#!perl -T
use strict;
use warnings qw(all);

use Test::Builder::Tester tests => 4;
use Test::More;

BEGIN {
    use_ok('Test::Mojibake');
}

BAD: {
    my ($name, $file);

    $name = 'Latin-1 with "use utf8"!';
    $file = 't/bad/bad-latin1.pl_';
    test_out("not ok 1 - $name");
    file_encoding_ok($file, $name);
    test_fail(-1);
    test_diag("Non-UTF-8 unexpected in $file, line 6 (source)");
    test_test("$name is bad");

    $name = 'UTF-8 with no "use utf8"!';
    $file = 't/bad/bad-utf8.pl_';
    test_out("not ok 1 - $name");
    file_encoding_ok($file, $name);
    test_fail(-1);
    test_diag("UTF-8 unexpected in $file, line 5 (source)");
    test_test("$name is bad");

    $name = 'no source at all';
    $file = 't/bad/dummy.pl_';
    test_out("not ok 1 - $name");
    file_encoding_ok($file, $name);
    test_fail(-1);
    test_diag("$file does not exist");
    test_test("$name is bad");
}
