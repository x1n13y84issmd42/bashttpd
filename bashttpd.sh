#!/bin/bash

netcat -lvk -p 8080 | ./handler.sh $1