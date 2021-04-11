package hexdisplay

import (
	"github.com/brian-armstrong/gpio"
)

const hexLowBase = 1856
const hexHighBase = 1888

var digits = []uint{
	0x40, 0x79, 0x24, 0x30, 0x19,
	0x12, 0x02, 0x78, 0x00, 0x10,
}

// Set the hex display at the GPIO base to the given digit.  Digit -1
// is blank.
func setDigit(hex int, digit int) {
	var pattern uint
	if digit < 0 || digit > 9 {
		pattern = 0xff
	} else {
		pattern = digits[digit]
	}

	var base uint
	if hex == 4 {
		for i := uint(0); i < 4; i++ {
			pin := gpio.NewOutput(hexLowBase+(i+28), (pattern>>i)&0x01 != 0)
			pin.Close()
		}
		for i := uint(0); i < 3; i++ {
			pin := gpio.NewOutput(hexHighBase+i, (pattern>>(i+4))&0x01 != 0)
			pin.Close()
		}
		return
	} else if hex < 4 {
		base = uint(hexLowBase + hex*7)
	} else if hex == 5 {
		base = hexHighBase + 3
	}

	for i := uint(0); i < 7; i++ {
		pin := gpio.NewOutput(base+i, (pattern>>i)&0x01 != 0)
		pin.Close()
	}
}

func DisplayPin(num int) {
	for i := 0; i < 4; i++ {
		setDigit(i, num%10)
		num /= 10
	}

	setDigit(5, -1)
	setDigit(4, -1)
}
