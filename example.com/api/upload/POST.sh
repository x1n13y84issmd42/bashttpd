name=$(reqData name)
age=$(reqData age)

respStatus 200
respHeader "Content-Type" "application/json"

respBody "{\"name\":\"$name\", \"age\":\"$age\"}"
