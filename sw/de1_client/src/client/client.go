package main

import (
	"fmt"
	"log"

	pb "github.com/CPEN391-Team-4/backend/pb/proto"
	"github.com/CPEN391-Team-4/hardware/sw/de1_client/src/bluetooth"
	"github.com/CPEN391-Team-4/hardware/sw/de1_client/src/devid"
	"github.com/CPEN391-Team-4/hardware/sw/de1_client/src/lock"
	"github.com/CPEN391-Team-4/hardware/sw/de1_client/src/loop"
	"github.com/CPEN391-Team-4/hardware/sw/de1_client/src/motion"
	"google.golang.org/grpc"
)

// Main function that controls the DE1
func main() {
	log.Println("starting up")

	devid.InitializeDeviceID()

	// Connect to backend
	conn, err := grpc.Dial("192.168.0.15:9000", grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		panic(err)
	}
	defer conn.Close()

	// Initialize the door bolt and motion sensor
	lock.Init()
	motion.Init()

	// Concurrently listen for bluetooth connections
	go bluetooth.Listen()

	// Create gRPC channels for streaming and face verification
	client := pb.NewRouteClient(conn)
	vidClient := pb.NewVideoRouteClient(conn)

	// Channels for concurrent communication
	reqs := make(chan loop.LoopReq)
	captureShutdown := make(chan struct{}, 1)
	streamState := make(chan bool, 1)

	// Detect motion, and monitor requests from the app concurrently.
	go motion.MotionDetect(reqs)
	go loop.CaptureLoop(client, vidClient, reqs, streamState, captureShutdown)
	go loop.MonitorRequests(client, vidClient, reqs, streamState)

	// Control DE1 from commandline
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
