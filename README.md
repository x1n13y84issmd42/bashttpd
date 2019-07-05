# Bashttpd
A web framework written in Bash script. It really do be like that sometimes.

## Requirements
`netcat`

## Using
`./bashttpd example.com`

Here `example.com` is a folder that contains a project.

## Design
When receiving a request, **bashttpd** tries to match the path from it to the folder structure of the supplied project. When a common node is found, it looks for `index.sh` in the project folder, and passes control to it.

## TODO
#### Static pages
#### A framework
Need something to arrange static resource controllers, MySQL controllers, some HTTP-related utilities, probably authentication & logging.

#### MySQL
