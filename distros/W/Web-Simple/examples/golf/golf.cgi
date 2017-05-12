#!/usr/bin/perl
use Web::Simple;
sub dispatch_request { [ 200, [ 'Content-type', 'text/plain' ], [ 'Hello world!' ] ] }
__PACKAGE__->run_if_script;
