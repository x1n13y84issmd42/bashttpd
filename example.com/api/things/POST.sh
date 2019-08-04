thingName=$(reqData ".[0].gender")
thingSize=$(reqData ".[0].age")

log "Thing name is $thingName"
log "Thing size is $thingSize"

respStatus 200
respHeader "Content-Type" "text/plain"
respBody "yolo"