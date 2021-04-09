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
const CHUNKS_PER_FRAME = IMG_HEIGHT_COMP * IMG_WIDTH_COMP / READ_BUF_SIZE
// const NUM_FRAMES = 32		// Chosen arbitrarily. Change later


// Edit so that we can stream indefinitely, rather than sending a finite, pre-defined number of frames
func streamVideo(client pb.VideoRouteClient, ctx context.Context, num_frames int) error {
	var frame pb.Frame
	stream, err := client.StreamVideo(ctx)
	if err != nil {
		log.Fatalf("%v.StreamVideo(_) = _, %v", client, err)
	}
	for i := 0; i < num_frames; i++{		// Iterate through frames (change looping condition)
		// Get frame:
		// Capture, compress frame, put in buffer
		buf := make([]byte, IMG_HEIGHT_COMP * IMG_WIDTH_COMP)	// This buffer is supposed to hold the frame

		for j := 0; j < CHUNKS_PER_FRAME; j++ {								// Iterate through chunks in frame
			//Put if statement so that we check when we need to stop streaming.

			frame.Chunk = buf[j * READ_BUF_SIZE : (j + 1) * READ_BUF_SIZE]	// Should be byte array of pixels of size READ_BUF_SIZE
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

func main() {
	ServerAddress := ":9000"
	motion := false
	stream := false

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
				if err = streamVideo(c, ctx, 10); err != nil {
					log.Fatalf("Couldn't stream: %v", err)
				}
				break
			}
			if stream == true {
				if err = streamVideo(c, ctx, 0); err != nil {		// num_frames == 0 => we want indefinite stream
					log.Fatalf("Couldn't stream: %v", err)
				}
				break
			}
		}

		/*
		 Capture 10 seconds of video if motion triggered stream, or until livestream is stopped if stream requested
		 Store in buffer
		 Send to backend
		*/
		
	}
}