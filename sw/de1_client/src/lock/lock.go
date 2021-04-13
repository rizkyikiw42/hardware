package lock

import (
	"github.com/brian-armstrong/gpio"
)

var lockPin gpio.Pin

var LockEngaged bool = true

const lockGpioNum = 1825

// Initialize GPIO connected to door lock
func Init() {
	lockPin = gpio.NewOutput(lockGpioNum, false)
}

// Lock or unlock door
func Lock(engaged bool) {
	LockEngaged = engaged
	if engaged {	// Lock
		lockPin.Low()
	} else {		// Unlock
		lockPin.High()
	}
}
