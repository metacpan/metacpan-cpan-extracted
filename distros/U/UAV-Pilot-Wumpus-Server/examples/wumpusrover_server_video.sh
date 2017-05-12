#!/bin/bash
WIDTH=1080
HEIGHT=720
FPS=25
BITRATE=2000000
PORT=49001

raspivid -t 0 -w ${WIDTH} -h ${HEIGHT} -fps ${FPS} -hf -b ${BITRATE} -o - \
    | wumpusrover_server_video -w ${WIDTH} -h ${HEIGHT} -t stdin
