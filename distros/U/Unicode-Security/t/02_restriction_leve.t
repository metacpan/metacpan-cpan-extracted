use strict;
use warnings;
use open ':std', ':encoding(utf-8)';
use Test::More;
use Unicode::Security qw(restriction_level);

my @test = (
    [ "_"                                         => 1 ],
    [ "ascii_only"                                => 1 ],
    [ "single_script_l\x{00E1}t\x{00EE}\x{00F1}1" => 2 ],


    [ "latin\x{6700}\x{308B}\x{30D4}" => 3 ],
    [ "\x{6700}\x{308B}\x{30D4}"      => 3 ],
    [ "\x{308B}\x{30D4}"              => 3 ],
    [ "\x{6700}\x{30D4}"              => 3 ],
    [ "latin\x{30D4}"                 => 3 ],
    [ "latin\x{6700}\x{310D}"         => 3 ],
    [ "latin\x{6700}\x{3162}"         => 3 ],

    [ "latin\x{1886}\x{189A}"         => 4 ],
    [ "latin\x{05D0}\x{05D4}\x{05E4}" => 4 ],

    [ "\x{03A9}mega" => 5 ],
    [ "Te\x{03C7}"   => 5 ],
    [
        "H\x{03BB}LF-LIFE" => 5,
        qr/[^\p{ID_Continue}-]/
    ], [
        "Toys-\x{042F}-Us" => 5,
        qr/[^\p{ID_Continue}-]/
    ],

    [ "I\x{2665}NY.org" => 0 ],
);

for my $test (@test) {
    my ($str, $level, $regex) = @$test;
    is restriction_level($str, $regex), $level, $str;
}

done_testing;
