#!/usr/bin/env perl
use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More tests => 1;

eval { require "SyntaxError.pm" };
like( $@, qr/\Asyntax error at /, 'Syntax Error reported correctly' );
