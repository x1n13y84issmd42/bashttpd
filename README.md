# Bashttpd
A web framework written in Bash script. It really do be like that sometimes.

## Requirements
`netcat` with enabled suport for scripting (the `-c` option).

## Usage
`./bashttpd example.com`

Here `example.com` is a path to a folder that contains a project.

Then visit `localhost:8080` in browser.

## Design
When **bashttpd** receives a request, it tries to match the path from that to the folder structure of the supplied project, and looks for a script file named after the HTTP request method used.

For example, a `GET` request to the `/foo/bar` path is served by the `example.com/foo/bar/GET.sh` script.

## Framework
There is one!

### Request headers
Request headers are available to the controller script under their names capitalized and dashes replaced by underscores. So a `Content-Type` header is accessible as `$CONTENT_TYPE` variable.

### Responding
Basically you can just `echo` anything, and it'll get to a client, but you'll need to follow the HTTP protocol yourself.

If you're not a fan (who is?), there are functions for that.

#### respStatus
Initiates a response by sending an `HTTP/1.1` header with the status you provide. Example: `respStatus 200`

#### respHeader
Writes an HTTP header. Example: `respHeader "Content-Type" "text/html"`

#### respBody
Writes the response body. Example: `respBody "<h1>YOLO</h1>"`

#### log
A logging function. Outputs to the host's `stderr`.

## TODO
#### Static pages
#### A framework
Need something to arrange static resource controllers, MySQL controllers, some HTTP-related utilities, probably authentication & logging.

#### MySQL
