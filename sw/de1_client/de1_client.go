package main

import (
	"context"
	"fmt"
	"io"
	"io/ioutil"
	"log"

	//"environment"
	pb "github.com/CPEN391-Team-4/backend/pb/proto"
	"google.golang.org/grpc"
)

const IMG_HEIGHT_COMP = 480
const IMG_WIDTH_COMP = 640
const READ_BUF_SIZE = 16
const CHUNKS_PER_FRAME = IMG_HEIGHT_COMP * IMG_WIDTH_COMP / READ_BUF_SIZE
const NUM_TEST_FRAMES = 100

func streamVideo(client pb.VideoRouteClient, ctx context.Context) error {
	var frame pb.Frame
	stream, err := client.StreamVideo(ctx)
	if err != nil {
		log.Fatalf("%v.StreamVideo(_) = _, %v", client, err)
	}
	for i := 0; i < NUM_TEST_FRAMES; i++{		// Iterate through frames
		// Get frame
		for j := 0; j < CHUNKS_PER_FRAME; j++ {	// Iterate through chunks in frame
			frame.Chunk = []byte{byte(j)}		// Should be byte array of pixels of size READ_BUF_SIZE
			frame.LastChunk = (j == CHUNKS_PER_FRAME - 1)
			frame.Number = int32(i)
			req := pb.Video{Frame: &frame, Name: "Test"}
			if err := stream.Send(&req); err != nil && err != io.EOF {
				log.Fatalf("%v.Send(%v) = %v", stream, &req, err)
			}
			log.Printf("Sent frame.Number=%v, frame.LastChunk=%v", frame.Number, frame.LastChunk)
		}
	}
	reply, err := stream.CloseAndRecv()
	if err != nil {
		log.Fatalf("%v.CloseAndRecv() got error %v, want %v", stream, err, nil)
	}
	log.Printf("Route summary: %v", reply)
	return nil
}

func verifyFace(client pb.RouteClient, ctx context.Context, buf []byte) (bool, error) {

	var photo pb.Photo
	stream, err := client.VerifyUserFace(ctx)
	if err != nil {
		log.Fatalf("%v.VerifyUserFace(_) = _, %v", client, err)
	}

	lastByteRead := -1
	len := len(buf)
	buf_end, verified := false, false

	for {

		if lastByteRead + READ_BUF_SIZE <= len {
			photo.Image = buf[lastByteRead : lastByteRead + READ_BUF_SIZE]
			lastByteRead += READ_BUF_SIZE
		} else {
			photo.Image = buf[lastByteRead : len]
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

func stream(vrc pb.VideoRouteClient, ctx context.Context) {
	motion := false

	for {
		for {
			// make request to see if client asking for video feed
			if motion {	// Change break condition so that we break from loop if motion detected or client asks for videofeed
				break
			}
		}

		/*
		 Capture 10 seconds of video if motion triggered stream, or until livestream is stopped if stream requested
		 Store in buffer
		 Send to backend
		*/

		if err := streamVideo(vrc, ctx); err != nil {
			log.Fatalf("Error with streaming: %v", err)
		}
	}
}

func unlock(rc pb.RouteClient, ctx context.Context) {
	motion := false	// Change after connecting to PIO for sensor/button

	// cam.Open()
	// defer cam.Close()
	for {
		for {
			if motion {	// Change break condition so that we break from loop if motion detected
				break
			}
		}

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

		frame, err := ioutil.ReadFile("test_img.jpg")
		if err != nil {
			log.Fatalf("failed to get test_img.jpg: %v", err)
		}

		// frame := make([]byte, READ_BUF_SIZE)		// Replace so that frame is the buffer that contains the raw image
		unlock, err := verifyFace(rc, ctx, frame)

		if err != nil {
			log.Fatalf("failed to verify face: %v", err)
		}

		if unlock {
			// Call function to unlock door
			fmt.Printf("Unlocked!")
		}

	}

}

func main() {
	ServerAddress := "192.53.126.159:9000"

	conn, err := grpc.Dial(ServerAddress, grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	vrc := pb.NewVideoRouteClient(conn)
	rc := pb.NewRouteClient(conn)
	fmt.Println(conn)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go stream(vrc, ctx)
	go unlock(rc, ctx)

}