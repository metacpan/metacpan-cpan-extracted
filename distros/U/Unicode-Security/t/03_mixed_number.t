use strict;
use warnings;
use open ':std', ':encoding(utf-8)';
use Test::More;
use Unicode::Security qw(mixed_number);

my @test = (
    [ '12345',               '' ],
    [ '123test',             '' ],
    [ '12,345,678.90',       '' ],
    [ "123\x{0664}\x{096E}", 1 ],
    [ "\x{0664}\x{096E}",    1 ],
    [ "\x{0664}\x{0667}",    '' ],
    [ "\x{0664}\x{0067}",    '' ],
);

for my $test (@test) {
    my ($str, $ret) = @$test;

    # Prevent lame warning from Test::Builder about not using numbers as test
    # names.
    my $name = ": $str";

    is mixed_number($str), $ret, $name;
}

done_testing;
