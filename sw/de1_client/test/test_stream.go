package main

import (
	"context"
	"io"
	"log"
	"time"

	pb "github.com/CPEN391-Team-4/backend/pb/proto"
	"google.golang.org/grpc"
)

const SERVER_ADDR = "192.53.126.159:9000"
const LOCAL_SERVER_ADDR = "172.26.163.79:9000"

func main() {
	ServerAddress := SERVER_ADDR

	conn, err := grpc.Dial(ServerAddress, grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	client := pb.NewVideoRouteClient(conn)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	
	<-time.After(10 * time.Second)

	pullStream, err := client.PullVideoStream(ctx, &pb.PullVideoStreamReq{Id: "default"})
	if err != nil {
		log.Fatalf("%v.PullVideoStream(_) = _, %v", client, err)
	}
	log.Printf("Stream Req")
	for i := 0; i < 16; i++ {
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

	endReq := pb.EndPullVideoStreamReq{Id: "test"}
	endStream, err := client.EndPullVideoStream(ctx, &endReq)
	if err != nil {
		log.Fatalf("Error: %v", err)
	}

	log.Printf("endStream:%v", *endStream)


}