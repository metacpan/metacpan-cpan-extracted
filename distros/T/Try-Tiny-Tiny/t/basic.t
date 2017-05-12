use strict; use warnings;
use Test::More;

use Try::Tiny::Tiny;
use Try::Tiny 'try';

#
#
#

plan tests => 1;

my $cb = sub { (caller 0)[3] };
my $name = &$cb;

is   &try($cb), $name, 'Try::Tiny is prevented from renaming its callback';
