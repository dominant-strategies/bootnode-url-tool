// Copyright 2015 The go-ethereum Authors
// This file is part of go-ethereum.
//
// go-ethereum is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// go-ethereum is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with go-ethereum. If not, see <http://www.gnu.org/licenses/>.

// bootnode runs a bootstrap node for the Ethereum Discovery Protocol.
package main

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"fmt"
	"math/big"
	"os"
	"path/filepath"

	"github.com/dominant-strategies/go-quai/cmd/utils"
	"github.com/dominant-strategies/go-quai/common"
	"github.com/dominant-strategies/go-quai/crypto"
)

func deriveNodeKey(keyfile string, location common.Location) *ecdsa.PrivateKey {
	curve := elliptic.P256()
	order := curve.Params().P
	// Load the node private key from the file
	seed, err := crypto.LoadECDSA(keyfile)
	if err != nil {
		utils.Fatalf("Failed to open keyfile", keyfile)
	}
	pkey := big.NewInt(0).Mod(seed.D, order)
	//// Tweak the private key to be unique for each location
	locationTweak := big.NewInt(0).SetBytes(crypto.Keccak256([]byte(location.Name())))
	locationTweak.Mod(locationTweak, order)
	tweakedKey := pkey.Mul(pkey, locationTweak)
	tweakedKey.Mod(tweakedKey, order)
	bytes := make([]byte, 32)
	copy(bytes, tweakedKey.Bytes())
	key, err := crypto.ToECDSA(bytes)
	if err != nil {
		utils.Fatalf("Failed to load private key", keyfile, err)
	}
	return key
}

func main() {
	// Check if command-line arguments are provided
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run nodekey-tool.go file1 file2 ...")
		return
	}

	// Iterate through the provided file paths
	for _, path := range os.Args[1:] {
		// Get the absolute path
		absPath, err := filepath.Abs(path)
		if err != nil {
			fmt.Printf("Error: %s\n", err)
			continue // Skip to the next path on error
		}
		// Check if the path is a file (not a directory)
		fileInfo, err := os.Stat(absPath)
		if err != nil {
			fmt.Printf("Error: %s\n", err)
			continue // Skip to the next path on error
		}
		if !fileInfo.Mode().IsRegular() {
			continue // Skip if it's not a regular file (e.g., a directory)
		}
		// Parse the IP address from the directory name
		dirName, _ := filepath.Split(absPath)
		ipAddress := filepath.Base(dirName)
		// Derive the enodes for the given keyfile
		primeLoc := common.Location{} // Prime
		nodekey := deriveNodeKey(absPath, primeLoc)
		nodeid := fmt.Sprintf("%x", crypto.FromECDSAPub(&nodekey.PublicKey)[1:])
		fmt.Printf("prime:\t\tenode://%s@%s\n", nodeid, ipAddress)
		for regionNum := 0; regionNum < common.NumRegionsInPrime; regionNum++ {
			regLoc := common.Location{byte(regionNum)}
			nodekey := deriveNodeKey(absPath, regLoc)
			nodeid := fmt.Sprintf("%x", crypto.FromECDSAPub(&nodekey.PublicKey)[1:])
			fmt.Printf("region-%d:\tenode://%s@%s\n", regionNum, nodeid, ipAddress)
		}
		for regionNum := 0; regionNum < common.NumRegionsInPrime; regionNum++ {
			for zoneNum := 0; zoneNum < common.NumZonesInRegion; zoneNum++ {
				zoneLoc := common.Location{byte(regionNum), byte(zoneNum)}
				nodekey := deriveNodeKey(absPath, zoneLoc)
				nodeid := fmt.Sprintf("%x", crypto.FromECDSAPub(&nodekey.PublicKey)[1:])
				fmt.Printf("zone-%d-%d:\tenode://%s@%s\n", regionNum, zoneNum, nodeid, ipAddress)
			}
		}
	}
}
