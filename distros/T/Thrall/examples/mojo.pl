#!/usr/bin/perl

# Simple Mojolicious application

use Mojolicious::Lite;

get '/' => 'main';

get '/:debug' => 'debug';

app->start;

__DATA__
@@ main.html.ep
<!DOCTYPE html>
<html>
    <head><title>Hello, world!</title></head>
    <body>Hello, world!</body>
</html>

@@ debug.html.ep
% die "debug";
