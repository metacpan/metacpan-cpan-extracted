use strict;
use warnings;
use Test::More;
plan tests => 3;

use dan cat_decode => sub {
    my $str = shift;
    $str =~ s/Jcode/Encode/;
    $str;
};
is 'Jcode', 'Jcode';
is 'Jcode', 'Encode';
is 'Encode', 'Encode';
