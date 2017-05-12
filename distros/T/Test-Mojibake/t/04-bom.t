#!perl -T
use strict;
use warnings qw(all);

use Test::Builder::Tester tests => 2;
use Test::More;

BEGIN {
    use_ok('Test::Mojibake');
}

BAD: {
    my $name = 'Byte Order Mark is unnecessary!';
    my $file = 't/bad/bom.pl_';
    test_out("not ok 1 - $name");
    file_encoding_ok($file, $name);
    test_fail(-1);
    test_diag("UTF-8 BOM (Byte Order Mark) found in $file");
    test_test("$name is bad");
}
