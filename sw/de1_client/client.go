package main

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"log"
	"os"

	//"environment"

	"google.golang.org/grpc"
)

const READ_BUF_SIZE = 16

func verifyFace(client pb.RouteClient, ctx context.Context, buf []byte) bool, error {

	var photo pb.Photo
	stream, err := client.VerifyUserFace(ctx)
	if err != nil {
		log.Fatalf("%v.VerifyUserFace(_) = _, %v", client, err)
	}

	lastByteRead := -1
	len := len(buf)
	buf_end, verified := false

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

		if buf_end == true {
			break
		}
	}

	reply, err := stream.CloseAndRecv()
	if err != nil {
		log.Fatalf("%v.CloseAndRecv() got error %v, want %v", stream, err, nil)
	}
	log.Printf("Route summary: %v", reply)

	if reply.confidence != 0 {
		verified = true
	}

	return verified, nil
}

func main() {
	ServerAddress := ":9000"
	motion := false	// Change after connecting to PIO for sensor/button

	conn, err := grpc.Dial(ServerAddress, grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	c := pb.NewRouteClient(conn)
	fmt.Println(conn)
	// fmt.Println(os.Args[1])

	// verifyFaceCmd := flag.NewFlagSet("verifyface", flag.ExitOnError)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	for {
		for {
			if motion == true {	// Change break condition so that we break from loop if motion detected
				break
			}
		}

		/*
		Capture and compress 1 frame
		Store in buffer
		Call verifyFace
		*/
		
		frame = make([]byte, READ_BUF_SIZE)		// Replace so that frame is the buffer that contains the raw image
		unlock, err := verifyFace(c, ctx, frame)

		if err != nil {
			log.Fatalf("failed to verify face: %v", err)
		}

		if unlock {
			// Call function to unlock door
		}

	}

	// if len(os.Args) < 2 {
	// 	fmt.Println("expected subcommand 'verifyface'")
	// 	os.Exit(1)
	// }

	// switch os.Args[1] {
	// case "verifyface":
	// 	verifyFaceCmd.Parse(os.Args[2:])
	// 	fmt.Println("subcommand 'verifyface'")
	// 	fmt.Println("  tail:", verifyFaceCmd.Args())
	// 	if len(verifyFaceCmd.Args()) < 1 {
	// 		fmt.Println("expected subcommand 'verifyface' FILE argument")
	// 		os.Exit(1)
	// 	}
	// 	_ = verifyFace(c, ctx, verifyFaceCmd.Args()[0])
	// default:
	// 	fmt.Println("expected 'verifyface' subcommand")
	// 	os.Exit(1)
	// }

	log.Println(c, ctx)
}