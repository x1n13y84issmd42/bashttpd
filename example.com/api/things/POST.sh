thingID=$(reqData "[0].id")
thingAge=$(reqData "[0].age")
thingMessage=$(reqData "[0].message")

log "Thing ID is $thingID"
log "Thing age is $thingAge"
log "Thing message is $thingMessage"

respStatus 200
respHeader "Content-Type" "text/plain"
respBody "yolo"