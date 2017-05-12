use strict;
use warnings;
use Test::More;
use lib 'lib';
use dan the => 'more';

plan tests => 1;
my $dan = Dan the 'Blogger';
is $dan, 'Blogger', 'Dan the Blogger';
