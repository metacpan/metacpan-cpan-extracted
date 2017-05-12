#!perl -T
use strict;
use warnings qw(all);

use Test::More tests => 4;

BEGIN {
    use_ok('Test::Mojibake');
}

for (qw(ascii latin1 utf8)) {
    my $file = 't/good/' . $_ . '.pod';
    file_encoding_ok($file, "$file encoding is OK");
}
