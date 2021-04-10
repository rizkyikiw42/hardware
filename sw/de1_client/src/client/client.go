package main

import (
	"github.com/CPEN391-Team-4/backend/sw/de1_client/src/bluetooth"
	"log"
)

func main() {
	log.Println("starting up")
	bluetooth.Listen()
	log.Println("shutting down")
}
