age=$(reqData "age")
name=$(reqData "name")
let visits=$(reqCookie "visit_counter")+1

respStatus 200
respHeader "Content-Type" "text/html"
respCookie "visit_counter" $visits

respTemplateFile "/assets/tpl/age.html"
