# Bashttpd
An HTTP server and a web framework, both written in pure Bash script. It really do be like that sometimes.

Bashttpd aims to implement the HTTP protocol and provide modern web development platform, while sticking to Bash Script and standard POSIX tools as much as possible.

## Requirements
`netcat` with enabled suport for scripting (the `-c` option).

[jq](https://stedolan.github.io/jq/) is you want JSON.

## Usage
`./bashttpd example.com`

Here `example.com` is a path to a folder that contains a project.

Then visit `localhost:8080` in browser.

## Design
When **bashttpd** receives a request, three things can hapen.

First, it tries to match the path from that to the folder structure of the supplied project, and looks for a script file named after the HTTP request method used.

For example, a `GET` request to the `/foo/bar` path is served by the `example.com/foo/bar/GET.sh` script.

If the request path matches a file path in the project directory, it will respond with it's contents. At the moment it supports `js`, `css` & `html`, as well as `jpeg` & `png` images with proper content types.

If none of the criterias above have matched, it'll try to interpret the requested path as a directory path and will try to find and serve `index.html` file from there.

## Framework
There is one! Bash Web Framework, or BWF, implements some standard operations expected from any modern web framework, making development of simple web apps in Bash script a breeze.

### Request Data
Structured request data (i.e. forms or JSONs) is available via the `reqData "fieldName"` function. It is mostly Content-Type agnostic, but for JSON requests it allows looking deeply through JSON structure with the [jq filter syntax](https://stedolan.github.io/jq/manual/#Basicfilters).

#### Headers
Request headers are available to controller scripts under their names capitalized and dashes replaced by underscores. So a `Content-Type` header is accessible as a `$CONTENT_TYPE` variable.

#### Supported Request Content Types
At the moment BWF understands `application/x-www-form-urlencoded` and `multipart/form-data` for forms, `application/json` for generic data.

| Function | Description | Example |
| --- | --- | --- |
| **reqCookie** | Outputs a value of a cookie from the request. |`SID=$(reqCookie "session_id")`|
|**reqData**|Outputs a single field value from the request body. Content-Type-agnostic.|`userName=$(reqData "userName")`|
|**reqFile**|Outputs a temporary file name where contents of the uploaded file is stored. Takes the name of the file as in form data.|`filePath=$(reqFile "theFile")`|
|**reqFileName**|Outputs original name of the uploaded file. Takes the name of the file as in form data.|`sourceFileName=$(reqFileName "theFile")`|
|**reqFileCT**|Outputs the Content-Type of the uploaded file. Takes the name of the file as in form data.|`fileCT=$(reqFileCT "theFile")`|
|**reqQuery**|Outputs a value of a query string parameter.|`page=$(reqQuery "page")`|

### Responding
Basically you can just `echo` anything, and it'll get to a client, but you'll need to follow the HTTP protocol yourself.

If you're not a fan (who is?), there are functions for that.

| Function | Description | Example |
| --- | --- | --- |
|**respStatus**|Initiates a response by sending an `HTTP/1.1` header with the status you provide.|`respStatus 200`|
|**respHeader**|Writes an HTTP header.|`respHeader "Content-Type" "text/html"`|
|**respCookie**|Sends a cookie to a client.|`respCookie "visit_counter" $counter`|
|**respBody**|Writes the response body.|`respBody "<h1>YOLO</h1>"`|
|**respFile**|Responds with a file contents. Note that you have to specify Content-Type yourself.|`respFile "/etc/passwd"`|
|**respTemplateFile**|Reads a file, expands variables into it, responds with the result.|`respTemplateFile "/assets/tpl/age.html"`|
|**respJSON**|A shorthand function to respond with JSONs. Encodes the passed data, sends Content-Type. |`declare -a FILE_LIST`<br>`# Fill the $FILE_LIST...`<br>`respJSON FILE_LIST`|
|**resp.CLI**|Formats the colored output (`\e[34;91m...\e[0m`) as HTML.|`HTML=$(resp.CLI $(ls -la --color=always ~))`|

### MySQL
| Function | Description | Example |
| --- | --- | --- |
|**mysql.Select**|Performs a simple SELECT MySQL query.<br>*$1* Table name to select from.<br>*$2* Optional WHERE clause.<br>*$3* Optional result reference name.|`mysql.Select image_comments "imageID='$imageID'" ROWS`|
|**mysql.Insert**|Performs an INSERT MySQL query. Result is an ID of the inserted row.<br>*$1* Table name to insert to.<br>*$2* An associative array with column data.<br>*$3* Optional result reference name.|`declare -A COMMENT=(`<br>`[imageID]=$(reqData imageID)`<br>`[message]=$(reqData message)`<br>`)`<br>`mysql.Insert image_comments COMMENT ID`|
|**mysql.foreach**|Alias. Iterates over MySQL query result rows. Expects the `ROWS` variable.|See below.|
|**mysql.row**|Alias. Must be called within the `mysql.foreach` loop, creates a lcoal `row` variable which is an associative array containing the row's column data.|`mysql.Select image_comments "imageID='$imageID'" ROWS`<br>`mysql.foreach; do`<br>`mysql.row`<br>`echo "Message is ${row[message]}"`<br>`done`|

### Utility
| Function | Description | Example |
| --- | --- | --- |
|**log**<br>**logg**<br>**loggg**<br>**logggg**<br>**loggggg**|A logging function. Outputs to the host's `stderr`.<br>The more **g**'s in the name, the higher **LOG_VERBOSITY** config value is required for the message to be displayed.|`log "User name is $name"`<br>`loggg "Not your everyday message"`|
|**var**|A syntactic sugar function which defines and initializes a dynamically named variable.|`var "DATA_$dataName" $dataValue`|
|**yield**|A syntactic sugar to output dynamic variables. A relative to the conventional `return` keyword.|`yield "DATA_$dataName"`|
|**urldecode**|A standard URL decoding function.|`decodedInput=$(urldecode $encodedInput)`|
|**urlencode**|A standard URL encoding function.|`encodedInput=$(urlencode $decodedInput)`|
|**sys.IFS**|Changes the IFS variable while backing it up and automatically restoring the previous value.|`sys.IFS ';'`|
|**sys.TimeElapsed**|A profiling function, outputs delta time between two consecutive calls, in seconds.|`$(sys.TimeElapsed)`<br>`T=$(sys.TimeElapsed)`|
|**sys.Time**|Outputs current unixtime.|`T=$(sys.Time)`|
|**sys.IFS**|A function to help preserve correct values for the IFS variable. Supports stacking.|`sys.IFS $'\r'`<br>`sys.IFS ';'`<br>`sys.IFS # IFS is $'\r' now`<br>`sys.IFS # IFS is default now`|


## TODO
* [x] Serve static resources
* [x] Serve binary resources (fonts, images, etc)
* [x] www-form-urlencoded requests
* [x] multipart/form-data (no binary files yet)
* [x] Handle uploaded files
* [x] Figure out binary request bodies
* [x] File uploading progress (JS)
* [x] Access data from application/json requests
* [ ] Access data from application/xml requests
* [x] application/json responses
* [x] Page templating
* [ ] Branches in templates
* [ ] Loops in templates
* [ ] Path parameters (/user/{ID})
* [x] Query String parsing
* [x] Cookies
* [x] MySQL
* [ ] MySQL migrations
* [x] Content url-en/decoding
* [ ] Socat port for parallelism?
* [x] Render colored CLI output as HTML (`ls --color=yes`)
* [x] Automatic error handling and reporting

## Links
https://superuser.com/questions/1368666/receiving-multiple-files-at-once-in-netcat-without-overwriting-last-file\
https://habr.com/ru/company/otus/blog/437114/\
https://linux.die.net/man/1/socat\
https://stuff.mit.edu/afs/sipb/machine/penguin-lust/src/socat-1.7.1.2/EXAMPLES\
https://gist.github.com/ramn/cfe0021b48c3e5d1f3f3\
https://gist.github.com/CMCDragonkai/87bf53c3f93ef5dcb7e4\

## XML
sudo apt-get install libxml-xpath-perl
cat testdata/uploadme.xml | xpath -e "//connection/host"