package bluetooth

import (
	"crypto/sha256"
	"encoding/hex"
	"log"
	"net"
	"strings"
	"time"

	"github.com/brian-armstrong/gpio"
	"github.com/tarm/serial"
)

const defaultNet = 2
const rfsDev = "/dev/ttyAL0"
const rfsBaud = 38400
const rfsGpioNum = 1920
const devName = "FaceLock"

func getDeviceID() (string, error) {
	iface, err := net.InterfaceByIndex(defaultNet)
	if err != nil {
		return "", err
	}

	netaddr := []byte(iface.HardwareAddr.String())
	hashaddr := sha256.Sum256(netaddr)
	deviceid := hex.EncodeToString(hashaddr[0:7])

	return deviceid, err
}

var rfsPort *serial.Port
var rfsPin gpio.Pin

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

	commandMode(true)
	// Reset the device.
	atCommand("AT+ORGL")
	atCommand("AT+NAME=" + devName)
	atCommand("AT+PSWD=9999")
	atCommand("AT+ROLE=0")
	commandMode(false)

	for {
		resp, err := readResponse()
		if err != nil {
			log.Println("error in RFS read: ", err)
		}

		log.Printf("got bluetooth cmd %v", resp)

		switch resp {
		case "devid":
			devid, err := getDeviceID()
			if err != nil {
				panic(err)
			}

			rfsPort.Write([]byte(devid + "\r\n"))
		}

	}
}

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

func atCommand(cmd string) (string, error) {
	cmdBytes := []byte(cmd + "\r\n")
	n, err := rfsPort.Write(cmdBytes)
	if err != nil || n != len(cmdBytes) {
		return "", err
	}

	return readResponse()
}
