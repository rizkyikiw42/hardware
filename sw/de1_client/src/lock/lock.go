package lock

import (
	"github.com/brian-armstrong/gpio"
)

var lockPin gpio.Pin

var LockEngaged bool = true

const lockGpioNum = 1825

func Init() {
	lockPin = gpio.NewOutput(lockGpioNum, false)
}

func Lock(engaged bool) {
	LockEngaged = engaged
	if engaged {
		lockPin.Low()
	} else {
		lockPin.High()
	}
}
