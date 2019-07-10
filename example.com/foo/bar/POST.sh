source $BWF

age=$(reqData "age")
name=$(reqData "name")

respStatus 200
respHeader "Content-Type" "text/html"

respBody "This is how we <b>POST</b><br/>Now we know that $name is $age years old"