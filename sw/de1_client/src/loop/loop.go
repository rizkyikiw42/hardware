// The main loop.
package loop

import (
	"context"
	"log"
	"time"

	pb "github.com/CPEN391-Team-4/backend/pb/proto"
	"github.com/CPEN391-Team-4/hardware/sw/de1_client/src/camera"
	"github.com/CPEN391-Team-4/hardware/sw/de1_client/src/devid"
	"github.com/CPEN391-Team-4/hardware/sw/de1_client/src/lock"
)

// How frequently to check for faces, when there's motion.
const verifyTime = 4 * time.Second

// A request to start/stop streaming, or to assert that motion is
// present.
type LoopReq = int

// How long to wake up for, when we detect motion.
const motionTime = 1 * time.Second

// How long to unlock the door for trusted users.
const unlockDuration = 5 * time.Second

const (
	StartStreamReq = iota
	StopStreamReq  = iota
	MotionReq      = iota
	QuitReq        = iota
)

// We loop around here the entire time, monitoring for motion/requests
// to stream.  We do it this way to simplify interleaving
// verifying/unlocking the door when motion is detected, and when we
// just want to stream.
func CaptureLoop(client pb.RouteClient, vidClient pb.VideoRouteClient,
	reqs chan LoopReq, streamState chan bool, finished chan struct{}) {
	frameTicker := time.NewTicker(time.Second / camera.CameraFPS)
	// frameTicker := time.NewTicker(1 * time.Second)
	verifyTicker := time.NewTicker(verifyTime)
	motionTimer := time.NewTimer(0)

	frameNum := 0

	var streaming bool
	var motion bool

	var err error
	var stream pb.VideoRoute_StreamVideoClient

	camera.Open()
	defer camera.Close()

	var buf []byte

	// Every time we react to a request to stream, we call this.
	// It checks to see if the stream is already going, and
	// starts/stops it accordingly.
	startStopStream := func() {
		if !streaming && stream != nil {
			// Close stream
			log.Println("stopped streaming")
			camera.Stop()
			stream.CloseAndRecv()
			stream = nil
		} else if streaming && stream == nil {
			// Start stream
			log.Println("started streaming")
			camera.Start()
			frameNum = 0
			// Create stream for gRPC
			stream, err = vidClient.StreamVideo(context.Background())
			if err != nil {
				log.Println("failed to start streaming ", err)
				return
			}

			// Send device ID
			err = stream.Send(&pb.Video{DeviceId: devid.DeviceID})
			if err != nil {
				log.Println("failed to send devid")
				return
			}

			streamState <- true
		}
	}

	// Loop for streaming, face verification, motion detection
loop:
	for {
		select {
		case req := <-reqs:
			switch req {
			// Start stream if not already streaming
			case StartStreamReq:
				if streaming {
					log.Println("tried to start streaming when already streaming")
				} else {
					streaming = true
					startStopStream()
				}

			// Stop stream if running
			case StopStreamReq:
				if !streaming {
					log.Println("tried to stop streaming when not streaming")
				} else if !motion {
					// Stop stream if there isn't any motion, else keep streaming
					streaming = false
					startStopStream()
					streamState <- false
				}

			// Set flag for motion detection and reset timer so that we start sending frames periodically
			// for face verification until timer runs out
			case MotionReq:
				log.Println("motion detected")
				motion = true
				// motionTimer.Reset(motionTime)

			// Set motion and streaming flags to false, stop and running streams, and break out of loop
			// when DE1 user requests to stop
			case QuitReq:
				motion = false
				streaming = false
				startStopStream()
				break loop
			}

		// Set motion flag to false when motion timer finishes
		case <-motionTimer.C:
			log.Println("motion expired")
			motion = false

		// Case when ticker to send frame to backend goes off
		case <-frameTicker.C:
			// If stream is running, capture and send a frame
			if streaming {
				buf, err = camera.Capture()
				if err != nil {
					log.Println("failed to capture a frame ", err)
					continue
				}

				// Creating frame message
				frame := pb.Video{
					Frame: &pb.Frame{
						Number:    int32(frameNum),
						LastChunk: true,
						Chunk:     buf,
					},
				}

				// Send frame
				err = stream.Send(&frame)
				if err != nil {
					log.Println("failed to send a frame ", err)
					continue
				}

				frameNum++
			}

		// Case when ticker for face verification goes off
		case <-verifyTicker.C:
			// If motion detected, capture a frame and send it to face verification stream
			if motion {
				motion = false
				log.Println("checking for faces in the frame")
				if !streaming {
					camera.Start()
				}
				// First image has artifacts.
				camera.Capture()
				buf, err = camera.Capture()
				if !streaming {
					camera.Stop()
				}
				if err != nil {
					log.Println("failed to capture a frame ", err)
					continue
				}

				// Start face verification stream
				faceStream, err := client.VerifyUserFace(context.Background())
				if err != nil {
					log.Println("failed to start face verify stream ", err)
					continue
				}

				// Send frame for face verification
				err = faceStream.Send(&pb.FaceVerificationReq{
					Photo: &pb.Photo{
						Image:         buf,
						FileExtension: "jpg",
					},
				})
				if err != nil {
					log.Println("couldn't send photo for face verification ", err)
					continue
				}

				// Receive response to determine whether to unlock or not
				resp, err := faceStream.CloseAndRecv()
				if err != nil {
					log.Println("didn't close face verify stream properly ", err)
					continue
				}

				log.Printf("trusted: %v, user: %s, confidence: %f",
					resp.Accept, resp.User, resp.Confidence)
				// If face verified, unlock door, wait until unlockDuration seconds, and lock door again
				if resp.Accept && lock.LockEngaged {
					lock.Lock(false)
					go func() {
						time.Sleep(unlockDuration)
						lock.Lock(true)
					}()
				}
			}
		}
	}

	finished <- struct{}{}
}

// Function to monitor requests coming from the app
func MonitorRequests(client pb.RouteClient, vidClient pb.VideoRouteClient,
	loopReqs chan LoopReq, streamState chan bool) {
	// Create stream to receive lock requests
	lockStream, err := client.RequestToLock(context.Background())
	if err != nil {
		panic(err)
	}

	// Create stream for livestream requests
	requestStream, err := vidClient.RequestToStream(context.Background())
	if err != nil {
		panic(err)
	}

	// Concurrently recieve response from backend that tells us if door unlock/lock is requested
	go func() {
		for {
			lockreq, err := lockStream.Recv()
			if err != nil {
				panic(err)
			}

			// Send response to backend to signifiy that request has been recieved
			lockStream.Send(&pb.LockConnection{Setup: true})

			// Lock or unlock door depending on request
			log.Println("locked: ", lockreq.Request)
			lock.Lock(lockreq.Request)
		}
	}()

	// Concurrently recieve response from backend that tells us if livestream is requested
	go func() {
		for {
			streamReq, err := requestStream.Recv()
			if err != nil {
				panic(err)
			}

			// Set flags if we request a request to livestream to begin livestreaming
			if streamReq.Request {
				loopReqs <- StartStreamReq
			} else {
				loopReqs <- StopStreamReq
			}

			// Send a response to requestStream channel if we have begun streaming
			state := <-streamState
			if state {
				requestStream.Send(&pb.InitialConnection{
					Setup: state,
				})
			}
		}
	}()
}
