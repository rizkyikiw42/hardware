package devid

import (
	"crypto/sha256"
	"encoding/hex"
	"log"
	"net"
)

const defaultNet = 2

var DeviceID string

// Initialize device ID for initial set-up with app
func InitializeDeviceID() {
	iface, err := net.InterfaceByIndex(defaultNet)
	if err != nil {
		panic(err)
	}

	netaddr := []byte(iface.HardwareAddr.String())
	hashaddr := sha256.Sum256(netaddr)
	DeviceID = hex.EncodeToString(hashaddr[0:7])

	log.Printf("devid: %s\n", DeviceID)
}
