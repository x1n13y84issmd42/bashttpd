COMMAND="ls -la --color=always ~"
CLIOUTPUT=$(resp.CLI $(ls -la --color=always ~))

resp.Status 200
resp.TemplateFile "ls.html"
