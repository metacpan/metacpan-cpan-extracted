use strict;
use warnings;

use Test::More;
use autobox::Colors;

my $blue  = 'hi there!'->blue;
my $plain = $blue->decolorize;

is $blue,  "\e[34mhi there!\e[0m", 'hi is blue';
is $plain, 'hi there!',            'hi is not blue';

done_testing;
