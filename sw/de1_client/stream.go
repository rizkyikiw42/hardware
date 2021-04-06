package main

import (
	"context"
	"fmt"
	"io"
	"log"

	//"environment"

	"google.golang.org/grpc"
)

const IMG_HEIGHT_COMP = 480
const IMG_WIDTH_COMP = 640
const READ_BUF_SIZE = 16
const CHUNKS_PER_FRAME = IMG_HEIGHT_COMP * IMG_WIDTH_COMP / READ_BUF_SIZE

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
			frame.LastChunk = (j == CHUCKS_PER_FRAME - 1)
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

func main() {
	ServerAddress := ":9000"
	motion := false

	conn, err := grpc.Dial(ServerAddress, grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	c := pb.NewVideoRouteClient(conn)
	fmt.Println(conn)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	for {
		for {
			// make request to see if client asking for video feed
			if motion == true {	// Change break condition so that we break from loop if motion detected or client asks for videofeed
				break
			}
		}

		/*
		 Capture 10 seconds of video if motion triggered stream, or until livestream is stopped if stream requested
		 Store in buffer
		 Send to backend
		*/

		if err := streamVideo(c, ctx); err != nil {
			log.Fatalf("Error with streaming: %v", err)
		}
	}
}