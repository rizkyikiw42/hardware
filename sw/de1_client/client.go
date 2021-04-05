package main

import (
	"bufio"
	"context"
	"flag"
	"fmt"
	"io"
	"log"
	"os"

	//"environment"

	"google.golang.org/grpc"
)

const READ_BUF_SIZE = 16

func verifyFace(client pb.RouteClient, ctx context.Context, file string) error {
	f, err := os.Open(file)
	if err != nil {
		return err
	}

	defer f.Close()

	reader := bufio.NewReader(f)
	buf := make([]byte, READ_BUF_SIZE)

	var photo pb.Photo
	stream, err := client.VerifyUserFace(ctx)
	if err != nil {
		log.Fatalf("%v.VerifyUserFace(_) = _, %v", client, err)
	}
	sizeTotal := 0
	for {
		n, err := reader.Read(buf)
		if err != nil {
			if err != io.EOF {
				return err
			}
			break
		}

		photo.Image = buf[0:n]
		req := pb.FaceVerificationReq{Photo: &photo}
		if err := stream.Send(&req); err != nil {
			log.Fatalf("%v.Send(%v) = %v", stream, &req, err)
		}
		sizeTotal += n
	}
	reply, err := stream.CloseAndRecv()
	if err != nil {
		log.Fatalf("%v.CloseAndRecv() got error %v, want %v", stream, err, nil)
	}
	log.Printf("Route summary: %v", reply)

	return nil
}

func main() {
	environ := environment.Env{}
	environ.ReadEnv()

	conn, err := grpc.Dial(environ.ServerAddress, grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	c := pb.NewRouteClient(conn)
	fmt.Println(conn)
	fmt.Println(os.Args[1])

	verifyFaceCmd := flag.NewFlagSet("verifyface", flag.ExitOnError)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	if len(os.Args) < 2 {
		fmt.Println("expected subcommand 'verifyface'")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "verifyface":
		verifyFaceCmd.Parse(os.Args[2:])
		fmt.Println("subcommand 'verifyface'")
		fmt.Println("  tail:", verifyFaceCmd.Args())
		if len(verifyFaceCmd.Args()) < 1 {
			fmt.Println("expected subcommand 'verifyface' FILE argument")
			os.Exit(1)
		}
		_ = verifyFace(c, ctx, verifyFaceCmd.Args()[0])
	default:
		fmt.Println("expected 'verifyface' subcommand")
		os.Exit(1)
	}

	log.Println(c, ctx)
}