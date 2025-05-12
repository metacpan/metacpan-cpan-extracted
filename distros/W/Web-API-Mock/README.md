# NAME

Web::API::Mock - It's new $module

# SYNOPSIS

    $ git clone  git@github.com:takihito/Web-API-Mock.git
    $ cpanm ./Web-API-Mock

    or

    $ cpanm Web::API::Mock

    :
    $ run-api-mock --help
    Usage:
            $ run-api-mock --files api.md --not-implemented-urls url.txt --port 8080

# DESCRIPTION

\## Install

&lt;pre>
$ git clone  git@github.com:takihito/Web-API-Mock.git
$ cpanm ./Web-API-Mock

or

$ cpanm Web::API::Mock

:
$ run-api-mock --help
Usage:
        $ run-api-mock --files api.md --not-implemented-urls url.txt --port 8080
&lt;/pre>

\## Create API Documentation

\* http://apiblueprint.org

&lt;pre>
\# api.md

\## GET /hello

\+ Response 200 (text/plain)

        Hello World
</pre>

\## Start Mock Server

&lt;pre>
$ run-api-mock --files api.md
HTTP::Server::PSGI: Accepting connections at http://0:5000
&lt;/pre>

\## Options

\* files
 \* API Document Files.

&lt;pre>
$ run-api-mock --files api1.md --files api2.md
&lt;/pre>

\* not-implemented-urls
 \* Add "501 Not Implemented" info (Method and URL).

&lt;pre>
GET,/hello/hoge
POST,/hello/foo
&lt;/pre>

\* port
 \* server port

\* Other...
 \* plackup options

\## Switch to the Production API

By using nginx

see not-implemented-urls option.

&lt;pre>
$ run-api-mock --files api.md --not-implemented-urls url.txt --port 5001
&lt;/pre>

&lt;pre>
upstream mock\_backend {
   server 127.0.0.1:5001;
}

upstream prod\_backend {
   server 127.0.0.1:5002;
}

server {

:
:

    location ~ ^/ {
         proxy_intercept_errors on;
         proxy_pass http://mock_backend;
         proxy_set_header Host $host;
    }

    error_page 501 =200 @prod;
    location @prod {
        proxy_pass http://prod_backend;
        proxy_set_header Host $host;
    }
</pre>

# LICENSE

Copyright (C) akihito.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

akihito <takeda.akihito@gmail.com>
