use warnings;
use strict;

use lib 't/lib';
use Test::More tests => 1;

eval { require "SyntaxError.pm" };
like( $@, qr/\Asyntax error at /, 'Syntax Error reported correctly' );
