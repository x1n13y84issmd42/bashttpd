counter=$(($(reqCookie "visit_counter")+1))
declare -A RESP=([visits]=$counter)

respStatus 200
respCookie "visit_counter" $counter
respJSON RESP
