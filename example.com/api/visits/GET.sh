let counter=$(reqCookie "visit_counter")+1

respStatus 200
respHeader "Content-Type" "application/json"
respCookie "visit_counter" $counter

respBody "{\"visits\":$counter}"
