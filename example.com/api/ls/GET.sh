COMMAND="ls -la --color=always ~"
CLIOUTPUT=$(resp.CLI $(ls -la --color=always ~))

respStatus 200
respTemplateFile "assets/tpl/ls.html"
