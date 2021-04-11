package main

import (
	"fmt"
	"log"

	pb "github.com/CPEN391-Team-4/backend/pb/proto"
	"github.com/CPEN391-Team-4/hardware/sw/de1_client/src/loop"
	"google.golang.org/grpc"
)

func main() {
	log.Println("starting up")

	conn, err := grpc.Dial("127.0.0.1:9000", grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		panic(err)
	}
	defer conn.Close()

	client := pb.NewRouteClient(conn)
	vidClient := pb.NewVideoRouteClient(conn)

	reqs := make(chan loop.LoopReq)
	captureShutdown := make(chan struct{}, 1)
	go loop.CaptureLoop(client, vidClient, reqs, captureShutdown)

loop:
	for {
		fmt.Print("> ")
		var cmd string
		fmt.Scanln(&cmd)

		switch cmd {
		case "start":
			reqs <- loop.StartStreamReq
		case "stop":
			reqs <- loop.StopStreamReq
		case "motion":
			reqs <- loop.MotionReq
		case "quit":
			reqs <- loop.QuitReq
			<-captureShutdown
			break loop
		default:
			fmt.Println("unknown command")
		}
	}

	log.Println("shutting down")
}
