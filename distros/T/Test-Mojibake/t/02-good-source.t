#!perl -T
use strict;
use warnings qw(all);

use Test::More tests => 5;

BEGIN {
    use_ok('Test::Mojibake');
}

for (qw(ascii.pl latin1.pl utf8.pl_ mojibake.pl_)) {
    my $file = 't/good/' . $_;
    file_encoding_ok($file, "$file encoding is OK");
}
