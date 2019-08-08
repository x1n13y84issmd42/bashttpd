package main

import (
	"fmt"
	"io/ioutil"
)

func main() {
	bytes15 := []byte("\n\n\n\x00\x00\x00\xaa\xbb\xcc\r\r\r\x00\xde\xad")
	bytes20 := []byte("\n\n\n\n\x00\x00\x00\x00\xaa\xbb\xcc\xdd\r\r\r\r\xde\xad\xbe\xef")
	bytesABCD := []byte("ABCD\n\n\n\nAB\rD\x00\x00\x00\x00\xde\xad\xbe\xef")
	bytesLS := []byte("\x00\xff\xff\xff\x00\x24\x80\xf4\x00\x24\x80\xf4\x00\x24\x80\xf4\x00\x24\x80\xf4\x2a\x24\x80\xf4\xc2")

	var err error
	err = ioutil.WriteFile("./testdata/15.bin", bytes15, 0777)
	err = ioutil.WriteFile("./testdata/20.bin", bytes20, 0777)
	err = ioutil.WriteFile("./testdata/ABCD.bin", bytesABCD, 0777)
	err = ioutil.WriteFile("./testdata/ls.bin", bytesLS, 0777)
	if err != nil {
		fmt.Println("Error", err)
	}

	fmt.Println("Yolo world")
}
