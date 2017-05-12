use strict;
use warnings;

use Test::More;
plan tests => 1;

use WWW::SmartSheet;
my $w = WWW::SmartSheet->new( token => 'faketoken' );
isa_ok($w, 'WWW::SmartSheet');


