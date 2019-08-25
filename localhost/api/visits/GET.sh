counter=$(($(req.Cookie "visit_counter")+1))
declare -A RESP=([visits]=$counter)

resp.Status 200
resp.Cookie "visit_counter" $counter
resp.JSON RESP
