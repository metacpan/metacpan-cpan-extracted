#!/usr/bin/env perl
use Mojolicious::Lite;
use lib app->home->rel_file('lib')->to_string;
push @{app->commands->namespaces}, 'TestCommand';
get '/' => {text => 'Hello!'};
app->start;
