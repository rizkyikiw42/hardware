package main

import (
	"context"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"time"

	//"environment"
	// cam "./src/camera"
	pb "github.com/CPEN391-Team-4/backend/pb/proto"
	"google.golang.org/grpc"
)

const IMG_HEIGHT_COMP = 480
const IMG_WIDTH_COMP = 640
const READ_BUF_SIZE = 16
const CHUNKS_PER_FRAME = IMG_HEIGHT_COMP * IMG_WIDTH_COMP / READ_BUF_SIZE
const NUM_TEST_FRAMES = 100
const SERVER_ADDR = "192.53.126.159:9000"

func requestStream(client pb.VideoRouteClient, ctx context.Context, startStream chan bool,
					streamUp chan bool, stop chan bool, errResp chan error) {

	stream, err := client.RequestToStream(ctx)
	if err != nil {
		errResp <- err
		return
	}
	go func() {
		for {
			log.Printf("requestStream recv pre")
			resp, err := stream.Recv()
			if err != nil {
				errResp <- err
				return
			}
			log.Printf("requestStream recv = %v", resp)

			startStream <- resp.Request

			log.Printf("requestStream startStream = %v", resp.Request)

			<- streamUp

			log.Printf("requestStream streamUp")

			err = stream.Send(&pb.InitialConnection{Setup: true})

			log.Printf("requestStream send = %v", true)
			if err != nil {
				errResp <- err
				return
			}
		}
	}()

	<- stop
	errResp <- stream.CloseSend()

	return
}

func streamVideo(client pb.VideoRouteClient, ctx context.Context, startStream chan bool, streamUp chan bool, stop chan bool, errResp chan error) {
	// Set up client
	frame := pb.Frame{}
	stream, err := client.StreamVideo(ctx)
	if err != nil {
		errResp <- err
		return
	}

	go func() {
		for {
			startNow := <-startStream
			if !startNow {
				continue
			}

			i := 0
			for {
				// Get frame
				buf, err := ioutil.ReadFile("dog.jpg")
				if err != nil {
					errResp <- err
					return
				}

				lastByte := 0
				length := len(buf)

				for {
					if lastByte+READ_BUF_SIZE <= length {
						frame.Chunk = buf[lastByte : lastByte+READ_BUF_SIZE]
						frame.LastChunk = false
					} else {
						frame.Chunk = buf[lastByte:]
						frame.LastChunk = true
					}
					frame.Number = int32(i)

					req := pb.Video{Frame: &frame, Name: "De1 Test"}
					if err := stream.Send(&req); err != nil && err != io.EOF {
						log.Fatalf("%v.Send(%v) = %v", stream, &req, err)
					}

					lastByte += READ_BUF_SIZE

					if lastByte > length {
						break
					}
				}

				if i == 0 {
					streamUp <- true
					log.Printf("streamVideo streamUp = %v", true)
				}

				log.Printf("streamVideo sentframe = %v", i)

				i++
			}
		}
	}()

	<- stop

	errResp <- stream.CloseSend()

	return
}

func verifyFace(client pb.RouteClient, ctx context.Context, buf []byte) (bool, error) {

	var photo pb.Photo
	stream, err := client.VerifyUserFace(ctx)
	if err != nil {
		log.Fatalf("%v.VerifyUserFace(_) = _, %v", client, err)
	}

	lastByte := 0
	len := len(buf)
	verified := false

	for {

		if lastByte + READ_BUF_SIZE <= len {
			photo.Image = buf[lastByte : lastByte + READ_BUF_SIZE]
		} else {
			photo.Image = buf[lastByte : ]
		}

		req := pb.FaceVerificationReq{Photo: &photo}
		if err := stream.Send(&req); err != nil {
			log.Fatalf("%v.Send(%v) = %v", stream, &req, err)
		}
		
		lastByte += READ_BUF_SIZE

		if lastByte > len {
			break
		}
	}

	reply, err := stream.CloseAndRecv()
	if err != nil && err != io.EOF {
		log.Fatalf("%v.CloseAndRecv() got error %v, want %v", stream, err, nil)
	}
	log.Printf("Route summary: %v", reply)

	log.Printf("Confidence: %v, Accept: %v", reply.Confidence, reply.Accept)
	if reply.Confidence != 0 {
		verified = true
	}

	return verified, nil
}

func unlock(rc pb.RouteClient, ctx context.Context, stop *bool) error {
	// motion := false	// Change after connecting to PIO for sensor/button

	// for {
		// for {
		// 	if motion {	// Change break condition so that we break from loop if motion detected
		// 		break
		// 	}
		// }

		/*
		Capture and compress 1 frame
		Store in buffer
		Call verifyFace
		*/
		// cam.Start()
		// frame, err := cam.Capture()
		frame, err := ioutil.ReadFile("johnny.jpg")

		if err != nil {
			log.Fatalf("failed to Capture image: %v", err)
		}
		// cam.Stop()

		unlock, err := verifyFace(rc, ctx, frame)

		if err != nil {
			log.Fatalf("failed to verify face: %v", err)
		}

		if unlock {
			// Call function to unlock door. Make sure function includes locking after 10 seconds
			fmt.Printf("Unlocked!\n")
		}

	// 	if *stop {
	// 		break
	// 	}

	// }

	return nil
}

func main() {
	ServerAddress := SERVER_ADDR

	conn, err := grpc.Dial(ServerAddress, grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	vrc := pb.NewVideoRouteClient(conn)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// cam.Open()
	// defer cam.Close()

	startStream, streamUp, stopReq, errReq := make(chan bool), make(chan bool), make(chan bool), make(chan error)
	go requestStream(vrc, ctx, startStream, streamUp, stopReq, errReq)

	stopStream, errStream := make(chan bool), make(chan error)
	go streamVideo(vrc, ctx, startStream, streamUp, stopStream, errStream)


	// go unlock(rc, ctx, &stop)

	//reader := bufio.NewReader(os.Stdin)
	//toStop, _ := reader.ReadString('\n')
	//
	//if toStop == "stop" {
	//	stop = true
	//}

	<-time.After(60 * time.Second)

	stopStream <- true
	stopReq <- true

	log.Printf("requestStream=%v", <-errReq)
	log.Printf("streamVideo=%v", <-errStream)

}