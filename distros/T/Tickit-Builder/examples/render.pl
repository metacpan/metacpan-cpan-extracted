#!/usr/bin/env perl 
use strict;
use warnings;
use IO::Async::Loop;
use Tickit::Async;
use Tickit::Builder;

sub usage {
	return <<"EOF";
Render a Tickit::Builder specification.

Usage:

 $0 layout.json

The layout.json file should contain an object ref (starting at
the root node). As a simple example:

 { widget => { type => 'Static', text => 'Hello, world' } }

EOF
}

my $file = shift or die usage();

my $layout = Tickit::Builder->new;
# We'll let the layout instance control the main event loop.
# If given a file as a parameter, will attempt to read from that
# file - assumes JSON content.
$layout->run($layout->parse_file($file));

