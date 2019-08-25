age=$(req.Data "age")
name=$(req.Data "name")
let visits=$(req.Cookie "visit_counter")+1

resp.Status 200
resp.Header "Content-Type" "text/html"
resp.Cookie "visit_counter" $visits

resp.TemplateFile "age.html"
