use strict;
use warnings;
use utf8;
use Test::More tests => 4;
use Unicode::Subscript ':all';

for my $sym (qw(subscript superscript TM SM)) {
    can_ok('main', $sym);
}

