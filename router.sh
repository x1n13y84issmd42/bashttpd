#!/bin/bash

function router() {
	if [ -d $1 ]; then
		echo "Found a controller"
	else
		echo "404 Not Found"
	fi
}