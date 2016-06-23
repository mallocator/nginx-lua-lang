# nginx-lua-lang

A lua script for nginx that will select a language based on either header, get parameter or cookie.
The script will return a value such as en-US and selects the best match based on what's available
and what defaults have been set by the user.

## How to use

To make use of this script you need to have nginx and the lua module installed. Under ubuntu this
can be found in the ```nginx-extras``` package.

Once installed the lua script can be used to determine the users language with the following sample
configuration:

```
server {
 listen 8080 default_server;
 index index.html index.htm;
 server_name localhost;

 set $lsup "en-US,en-UK,en-AU,pt-PT,pt-BR";
 set $ldef "en:en-US,pt:pt-BR";
 set $lfallback "en-US";
 set $lparam "lang";
 set_by_lua_file $lang /etc/nginx/lang.lua $lsup $ldef $lfallback $lparam;

 root /var/www/;

 location = / {
  try_files $uri $uri/ =404;
   if ($lang ~ 'pt' ) {
      rewrite (.*) $scheme://$server_name/pt$1;
  }
 }
}
```

You can pass up to 4 parameters to the script, the variable from the example above are used for
reference:

 * ```lsup``` (required) = list with available translations
 * ```ldef``` (recommended) = map with defaults for multiple files
 * ```lfallback``` (defaults to "en-US") = default if nothing else matches
 * ```lparam``` (defaults to "lang") = parameter name to look for in cookies and get params


## Parameter format

The default parameter format for Accept-Language is supported. A few examples of what you could
send:

 * Just the language: ```en```
 * The full locale: ```en-US```
 * The script ignores case: ```en-us```
 * Multiple options: ```en-US,en```
 * Multiple options for multiple languages: ```en-US,en,de-DE,de```
 * Http header format: ```Accept-Language: en-US,en;q=0.8,de-DE;q=0.6```
 * Alternative header format: ```Content-Language: En-US,en;q=0.8,de-DE;q=0.6,de;q=0.4```


## Testing

So how do you figure out if your script works? There doesn't seem to be an easy way to log
information to console. The first thing you want to do is disable script caching. To do so go to
your nginx.conf file which on ubuntu is located at ```/etc/nginx/nginx.cong``` and add this
directive to one of the valid directices ("http {}" is on option): ```lua_code_cache off;```.
For more information you can take a look at the [official documentation](https://github.com/openresty/lua-nginx-module#lua_code_cache).

Next it might be easiest to just output the result of a script without much clutter and other
scripts running. Going from the configuration in the example above you can just simply return the
language value instead of looking up documents. You can make use of this configuration:

```
server {
 listen 8080 default_server;
 index index.html index.htm;
 server_name localhost;

 set $lsup "en-US,en-UK,en-AU,pt-PT,pt-BR";
 set $ldef "en:en-US,pt:pt-BR";
 set $lfallback "en-US";
 set $lparam "lang";
 set_by_lua_file $lang /etc/nginx/lang.lua $lsup $ldef $lfallback $lparam;

 root /var/www/;

 location = / {
   add_header Content-Type text/plain;
   return 200 $lang;
 }
}
```

With this the response will only be the value of what $lang has been set to. Not the most elegant debugging option, but it works. If you want to use a browser rather than curl, use "add_header Content-Type text/plain;".

Alternatively, you can use "ngx.log(ngx.ALERT, "message: "..variable)" to debug with tailing into the nginx error logs, or test with a local lua script with 'rex = require "rex_pcre"' as ngx.re replacement.

Finally you might want to send requests to nginx to test your settings. The easiest way (on nix)
is to use curl. Here are some simple example for curl:

 * Using cookies: ```curl -v --cookie "lang=en-US" http://localhost```
 * Using headers: ```curl -v --header "Accept-Language: en-US" http://localhost```
 * Using parameters: ```curl -v http://localhost?lang=en-US```
