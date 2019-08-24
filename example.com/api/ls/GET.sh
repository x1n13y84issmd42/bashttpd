respStatus 200

COMMAND="ls -la --color=always"
COMMAND="ls -la --color=always ~"
coloredOutput=($(ls -la --color=always ~))
CLIOUTPUT=$(bwf.respCLI ${coloredOutput[@]})

respTemplateFile "assets/tpl/ls.html"