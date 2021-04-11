package main

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
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

func requestStream(client pb.VideoRouteClient, ctx context.Context, stop *bool) error {
	reqStream, err := client.RequestToStream(ctx)
	if err != nil {
		log.Fatalf("%v.RequestToStream(_) = _, %v", client, err)
	}
	up := make(chan bool)
	streaming := make(chan bool)
	stopStreaming := make(chan bool)

	go func() {
		for {
			streamNow := <- up
			if streamNow {
				log.Printf("streamVideo")
				err := streamVideo(client, ctx, streaming, stopStreaming)
				if err != nil {
					log.Fatal(err)
				}
			}
			if *stop {
				break
			}
		}
	}()

	go func() {
		for {
			reply, err := reqStream.Recv()
			if reply.Request {
				up <- true
				// stopStreaming <- false
			}

			log.Printf("Before streaming")
			<- streaming
			err = reqStream.Send(&pb.InitialConnection{Setup: true})
			log.Printf("Send setup true")
			if err != nil {
				log.Fatal(err)
			}
			if *stop || !reply.Request {
				// up <- false
				stopStreaming <- true
				if *stop {
					break
				}
			}
		}
	}()

	// go func() {
	// 	for {
	// 		streamNow := <-up
	// 	}
	// }()

	// go func() {
	// 	for {

	// 	}
	// }()

	<-time.After(10 * time.Second)

	pullStream, err := client.PullVideoStream(ctx, &pb.PullVideoStreamReq{Id: "default"})
	if err != nil {
		log.Fatalf("%v.PullVideoStream(_) = _, %v", client, err)
	}

	for {
		reply, err := pullStream.Recv()
		if err != nil {
			if err == io.EOF {
				break
			}
			log.Fatalf("%v.Recv() = %v", pullStream, err)
		}
		if reply.Video != nil && reply.Video.Frame != nil {
			log.Printf("Recieved Frame.Number=%v", reply.Video.Frame.Number)
		}

		if reply.Closed {
			log.Printf("Stream closed")
			break
		}
	}

	return nil
}

func streamVideo(client pb.VideoRouteClient, ctx context.Context, streaming chan bool, stopStreaming chan bool) error {
	// Set up client
	frame := pb.Frame{}
	stream, err := client.StreamVideo(ctx)
	if err != nil {
		log.Fatalf("%v.StreamVideo(_) = _, %v", client, err)
	}

	i := 0
	for {
		// Get frame
		buf, err := ioutil.ReadFile("dog.jpg")
		// cam.Start()
		// buf, err := cam.Capture()
		// cam.Stop()

		if err != nil {
			log.Fatalf("failed to Capture image: %v", err)
		}
		
		lastByte := 0
		len := len(buf)

		for {
			if lastByte + READ_BUF_SIZE <= len {
				frame.Chunk = buf[lastByte : lastByte + READ_BUF_SIZE]
				frame.LastChunk = false
			} else {
				frame.Chunk = buf[lastByte : ]
				frame.LastChunk = true
			}
			frame.Number = int32(i)

			req := pb.Video{Frame: &frame, Name: "Test"}
			if err := stream.Send(&req); err != nil && err != io.EOF {
				log.Fatalf("%v.Send(%v) = %v", stream, &req, err)
			}

			lastByte += READ_BUF_SIZE

			if lastByte > len {
				break
			}
		}

		if i == 0 && stream != nil {
			//
			streaming <- true
			//
		}

		i++

		stop := <- stopStreaming
		if stop {
			// streamReqClient.Close()
			break
		}
	}

	reply, err := stream.CloseAndRecv()
	if err != nil && err != io.EOF {
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
	// rc := pb.NewRouteClient(conn)
	fmt.Println(conn)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	stop := false

	// cam.Open()
	// defer cam.Close()

	go requestStream(vrc, ctx, &stop)
	// go unlock(rc, ctx, &stop)

	reader := bufio.NewReader(os.Stdin)
	toStop, _ := reader.ReadString('\n')

	if toStop == "stop" {
		stop = true
	}

}