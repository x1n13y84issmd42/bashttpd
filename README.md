# Bashttpd
An HTTP server and a web framework, both written in pure Bash script. It really do be like that sometimes.

## Requirements
`netcat` with enabled suport for scripting (the `-c` option).

## Usage
`./bashttpd example.com`

Here `example.com` is a path to a folder that contains a project.

Then visit `localhost:8080` in browser.

## Design
When **bashttpd** receives a request, it tries to match the path from that to the folder structure of the supplied project, and looks for a script file named after the HTTP request method used.

For example, a `GET` request to the `/foo/bar` path is served by the `example.com/foo/bar/GET.sh` script.

But if the request path matches a file path in the project directory, it will respond with it's contents. At the moment it supports `js`, `css` & `html`, as well as `jpeg` images with proper content types.

## Framework
There is one!

### Request data

#### Headers
Request headers are available to the controller script under their names capitalized and dashes replaced by underscores. So a `Content-Type` header is accessible as `$CONTENT_TYPE` variable.

#### Request bodies
At the moment only partial support for multipart/form-data is implelmented (only fields, no files).

#### reqData
Outputs a single field value from the request body. Note that you need to capture it's output. Example: `userName=$(reqData "userName")`

### Responding
Basically you can just `echo` anything, and it'll get to a client, but you'll need to follow the HTTP protocol yourself.

If you're not a fan (who is?), there are functions for that.

#### respStatus
Initiates a response by sending an `HTTP/1.1` header with the status you provide. Example: `respStatus 200`

#### respHeader
Writes an HTTP header. Example: `respHeader "Content-Type" "text/html"`

#### respBody
Writes the response body. Example: `respBody "<h1>YOLO</h1>"`

#### respFile
Responds with a file contents. Note that you have to specify Content-Type yourself. Example: `respFile "/etc/passwd"`

#### log
A logging function. Outputs to the host's `stderr`.

## TODO
* ~~Static resources~~
* ~~Binary resources (fonts, images, etc)~~
* ~~www-form-urlencoded requests~~
* multipart/form-data requests partially supported (no files yet)
* application/json requests
* application/json responses
* Page templating
* Query String parsing
* Cookies
* MySQL
* JSON
