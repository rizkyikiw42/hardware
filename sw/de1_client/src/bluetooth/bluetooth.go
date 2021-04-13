package bluetooth

import (
	"fmt"
	"log"
	"math/rand"
	"strings"
	"time"

	"github.com/brian-armstrong/gpio"
	"github.com/tarm/serial"

	"github.com/CPEN391-Team-4/hardware/sw/de1_client/src/devid"
	"github.com/CPEN391-Team-4/hardware/sw/de1_client/src/hexdisplay"
)

const rfsDev = "/dev/ttyAL0"
const rfsBaud = 38400
const rfsGpioNum = 1920
const devName = "FaceLock"

var rfsPort *serial.Port
var rfsPin gpio.Pin

var bluetoothPin int

// Listen for bluetooth connections and send inquiring phones our
// device ID.
func Listen() {
	config := &serial.Config{Name: rfsDev, Baud: rfsBaud}
	port, err := serial.OpenPort(config)
	rfsPort = port
	if err != nil {
		panic(err)
	}
	defer rfsPort.Close()

	rfsPin = gpio.NewOutput(rfsGpioNum, true)
	defer rfsPin.Close()

	// Generate a random pin.
	rand.Seed(time.Now().UTC().UnixNano())
	bluetoothPin := rand.Intn(10000)
	log.Printf("generated pin %04d", bluetoothPin)
	// And show it
	hexdisplay.DisplayPin(bluetoothPin)

	commandMode(true)
	// Reset the device.
	atCommand("AT+ORGL")
	atCommand("AT+NAME=" + devName)
	atCommand(fmt.Sprintf("AT+PSWD=%04d", bluetoothPin))
	atCommand("AT+ROLE=0")
	commandMode(false)

	for {
		// Check for response. Send response if valid
		resp, err := readResponse()
		if err != nil {
			log.Println("error in RFS read: ", err)
		}

		log.Printf("got bluetooth cmd %v\n", resp)

		switch resp {
		case "devid":
			rfsPort.Write([]byte(devid.DeviceID + "\r\n"))
		}

	}
}

// Function to switch to command mode on RFS bluetooth
func commandMode(on bool) {
	if on {
		rfsPin.High()
	} else {
		rfsPin.Low()
	}

	// Give the module some time to react.
	time.Sleep(100 * time.Millisecond)
}

// Read a CRLF-terminated response from the RFS.
func readResponse() (string, error) {
	buf := make([]byte, 128)
	var seenCR bool
	var builder strings.Builder
	for {
		n, err := rfsPort.Read(buf)
		if err != nil {
			return "", err
		}

		builder.Write(buf[0:n])

		if buf[n-1] == '\r' {
			seenCR = true
		}

		if seenCR && buf[n-1] == '\n' {
			break
		}
	}

	str := builder.String()
	return str[0 : len(str)-2], nil
}

// Function to execute command passed to it
func atCommand(cmd string) (string, error) {
	cmdBytes := []byte(cmd + "\r\n")
	n, err := rfsPort.Write(cmdBytes)
	if err != nil || n != len(cmdBytes) {
		return "", err
	}

	return readResponse()
}
