package main

import (
	"os"

	"github.com/CPEN391-Team-4/backend/sw/de1_client/src/camera"
)

// Do a test capture
func main() {
	camera.Open()
	defer camera.Close()

	camera.Start()
	camera.Capture()
	out, _ := camera.Capture()
	camera.Stop()
	f, _ := os.Create("out.jpg")
	f.Write(out)
	f.Close()
}
