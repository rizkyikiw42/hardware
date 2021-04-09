package main

import (
	"bufio"
	"context"
	"fmt"
	"io/ioutil"
	"log"
	"os"

	//"environment"
	pb "github.com/CPEN391-Team-4/backend/pb/proto"
	"google.golang.org/grpc"
)

const IMG_HEIGHT_COMP = 480
const IMG_WIDTH_COMP = 640
const READ_BUF_SIZE = 16
const CHUNKS_PER_FRAME = IMG_HEIGHT_COMP * IMG_WIDTH_COMP / READ_BUF_SIZE
const NUM_TEST_FRAMES = 100
const SERVER_ADDR = "192.53.126.159:9000"

func streamVideo(client pb.VideoRouteClient, ctx context.Context, stop *bool) error {
	var frame pb.Frame
	stream, err := client.StreamVideo(ctx)
	if err != nil {
		log.Fatalf("%v.StreamVideo(_) = _, %v", client, err)
	}

	// var in pb.InitialConnection
	// in.Setup = true
	// streamReqClient, err := client.RequestToStream(ctx, &in)
	// if err != nil {
	// 	log.Fatalf("%v.RequestToStream() got error %v, want %v", client, err, nil)
	// }

	i := 0
	for {
		// Check if stream is being requested
		// strReq, err := streamReqClient.Recv()
		// if err != nil {
		// 	log.Fatalf("%v.RequestToStream() got error %v, want %v", client, err, nil)
		// }

		//if strReq.Request {

			// Get frame
			buf, err := ioutil.ReadFile("test_img1.jpg")

			if err != nil {
				log.Fatalf("failed to get test_img.jpg: %v", err)
			}

			// for j := 0; j < CHUNKS_PER_FRAME; j++ {	// Iterate through chunks in frame
			// 	frame.Chunk = []byte{byte(j)}		// Should be byte array of pixels of size READ_BUF_SIZE
			// 	frame.LastChunk = (j == CHUNKS_PER_FRAME - 1)
			// 	frame.Number = int32(i)
			// 	req := pb.Video{Frame: &frame, Name: "Test"}
			// 	if err := stream.Send(&req); err != nil {
			// 		log.Fatalf("%v.Send(%v) = %v", stream, &req, err)
			// 	}
			// 	log.Printf("Sent frame.Number=%v, frame.LastChunk=%v", frame.Number, frame.LastChunk)
			// }
			
			lastByte := 0
			len := len(buf)
			buf_end := false

			for {
				if lastByte + READ_BUF_SIZE < len {
					frame.Chunk = buf[lastByte : lastByte + READ_BUF_SIZE]
					frame.LastChunk = false
					lastByte += READ_BUF_SIZE
				} else {
					frame.Chunk = buf[lastByte : ]
					frame.LastChunk = true
					buf_end = true
				}
				frame.Number = int32(i)

				req := pb.Video{Frame: &frame, Name: "Test"}
				if err := stream.Send(&req); err != nil {
					log.Fatalf("%v.Send(%v) = %v", stream, &req, err)
				}

				if buf_end {
					break
				}
			}
			i++

		// } else {
			i = 0

			reply, err := stream.CloseAndRecv()
			if err != nil {
				log.Fatalf("%v.CloseAndRecv() got error %v, want %v", stream, err, nil)
			}
			log.Printf("Route summary: %v", reply)
		// }
		if *stop {
			break
		}
	}
	
	return nil
}

func verifyFace(client pb.RouteClient, ctx context.Context, buf []byte) (bool, error) {

	var photo pb.Photo
	stream, err := client.VerifyUserFace(ctx)
	if err != nil {
		log.Fatalf("%v.VerifyUserFace(_) = _, %v", client, err)
	}

	lastByte := 0
	len := len(buf)
	buf_end, verified := false, false

	for {

		if lastByte + READ_BUF_SIZE < len {
			photo.Image = buf[lastByte : lastByte + READ_BUF_SIZE]
			lastByte += READ_BUF_SIZE
		} else {
			photo.Image = buf[lastByte : ]
			buf_end = true
		}

		req := pb.FaceVerificationReq{Photo: &photo}
		if err := stream.Send(&req); err != nil {
			log.Fatalf("%v.Send(%v) = %v", stream, &req, err)
		}

		if buf_end {
			break
		}
	}

	reply, err := stream.CloseAndRecv()
	if err != nil {
		log.Fatalf("%v.CloseAndRecv() got error %v, want %v", stream, err, nil)
	}
	log.Printf("Route summary: %v", reply)

	if reply.Confidence != 0 {
		verified = true
	}

	return verified, nil
}

func unlock(rc pb.RouteClient, ctx context.Context, stop *bool) error {
	// motion := false	// Change after connecting to PIO for sensor/button

	// cam.Open()
	// defer cam.Close()
	for {
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

		// if err != nil {
		// 	log.Fatalf("failed to Capture image: %v", err)
		// }
		// cam.Stop()

		frame, err := ioutil.ReadFile("test_img2.jpg")
		if err != nil {
			log.Fatalf("failed to get test_img.jpg: %v", err)
		}

		// frame := make([]byte, READ_BUF_SIZE)		// Replace so that frame is the buffer that contains the raw image
		unlock, err := verifyFace(rc, ctx, frame)

		if err != nil {
			log.Fatalf("failed to verify face: %v", err)
		}

		if unlock {
			// Call function to unlock door. Make sure function includes locking after 10 seconds
			fmt.Printf("Unlocked!")
		}

		if *stop {
			break
		}

	}

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
	// src := pb.NewRouteClient(conn)
	fmt.Println(conn)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	stop := false
	
	go streamVideo(vrc, ctx, &stop)
	//go unlock(rc, ctx, &stop)

	reader := bufio.NewReader(os.Stdin)
	toStop, _ := reader.ReadString('\n')

	if toStop == "stop" {
		stop = true
	}

}