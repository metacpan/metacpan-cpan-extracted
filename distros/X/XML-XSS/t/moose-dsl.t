use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 1;                      # last test to print

use MyStylesheet;

my $xss = MyStylesheet->new;

my $rendered = $xss->render( '<doc><foo>hi</foo></doc>' );

is $rendered => '<doc>[pre-foo]hi[post-foo]</doc>';


