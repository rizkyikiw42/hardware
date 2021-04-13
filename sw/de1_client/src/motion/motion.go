package motion

import (
	"log"
	"time"

	"github.com/brian-armstrong/gpio"

	"github.com/CPEN391-Team-4/hardware/sw/de1_client/src/loop"
)

const motionGPIO = 1824
const doorbellGPIO = 1952
const modeGPIO = 1984

var motionPin gpio.Pin
var doorbellPin gpio.Pin
var modePin gpio.Pin

const pollPeriod = 100 * time.Millisecond

func Init() {
	motionPin = gpio.NewInput(motionGPIO)
	doorbellPin = gpio.NewInput(doorbellGPIO)
	modePin = gpio.NewInput(modeGPIO)
}

func MotionDetect(reqs chan loop.LoopReq) {
	ticker := time.NewTicker(pollPeriod)

	for {
		<-ticker.C

		var err error
		motion := false

		// Motion detector enabled.
		mode, err := modePin.Read()
		if err != nil {
			log.Println("error reading mode pin", err)
			continue
		}
		if mode == 0 {
			motionI, err := motionPin.Read()
			motion = motion || (motionI != 0)
			if err != nil {
				log.Println("error reading motion pin", err)
				continue
			}

		}

		motionI, err := doorbellPin.Read()
		if err != nil {
			log.Println("error reading doorbell pin", err)
			continue
		}

		motion = motion || (motionI == 0)

		if motion {
			reqs <- loop.MotionReq
		}
	}
}
