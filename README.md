Error-Logger
============
The PHP Error Logger receives PHP notices, warnings, errors and exceptions and places them in an easy-to-read and manage table.  The Error logger allows you to filter by error type (e.g. Notice or Exception) or search within error messages.

Prerequisites
------------
- Ruby >= 1.9.3
- MongoDB installed ("brew install mongo")

Installation
------------
1. Clone this repo into a directory on your local.
2. Run "rake start"
3. "rake start" will run the bundle script the first time it is run to install necessary gems.
4. "rake start" will run shotgun and mongo simultaneously.  Visit the page at http://127.0.0.1:9393.

5. Place the following code somewhere in your Drupal PHP script:

```php
set_error_handler('php_error_logger_log_msg');
function php_error_logger_log_msg($errno, $errstr, $errfile, $errline) {
  $page = $_SERVER['REQUEST_URI'];
  $a = array(
    'level' => $errno,
    'page' => $page,
    'message' => $errstr,
    'file' => $errfile,
    'line' => $errline,
    'time' => time(),
  );

  $d = '';
  foreach ($a AS $key => $val) {
    $d .= "$key=$val&";
  }
  $d = substr($d, 0, -1);

  // Send the post data.
  $options = array(
    'headers' => array(
      'Content-type' => 'application/x-www-form-urlencoded',
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    ),
    'method' => 'POST',
    'data' => $d,
  );

  $result = drupal_http_request('http://127.0.0.1:9393/write', $options);
}
```

6. You're done! Browse around your site and errors will be automatically submitted to the error logger.