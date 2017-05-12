#!perl

use strict;
use warnings;
use lib 't';

use Test::More tests => 1604;
use Util       qw[pack_utf8];

BEGIN {
    use_ok('Unicode::UTF8', qw[ decode_utf8 ]);
}

my @tests = (
    [ "\x80",               "\x{FFFD}" x 1 ],
    [ "\x80\x80",           "\x{FFFD}" x 2 ],
    [ "\x80\x80\x80",       "\x{FFFD}" x 3 ],
    [ "\xC0\x80",           "\x{FFFD}" x 2 ],
    [ "\xC1\x80",           "\x{FFFD}" x 2 ],
    [ "\xC2",               "\x{FFFD}" x 1 ],
    [ "\xE0\x80\x80",       "\x{FFFD}" x 3 ],
    [ "\xE0\xA0",           "\x{FFFD}" x 1 ],
    [ "\xE0\x9F\x80",       "\x{FFFD}" x 3 ],
    [ "\xED\xA0\x80",       "\x{FFFD}" x 3 ],
    [ "\xED\x80",           "\x{FFFD}" x 1 ],
    [ "\xED\xBF\x80",       "\x{FFFD}" x 3 ],
    [ "\xF0\x80\x80\x80",   "\x{FFFD}" x 4 ],
    [ "\xF0\x90\x80",       "\x{FFFD}" x 1 ],
    [ "\xF0\x8F\x80\x80",   "\x{FFFD}" x 4 ],
    [ "\xF4\x80\x80",       "\x{FFFD}" x 1 ],
    [ "\xF4\x90\x80\x80",   "\x{FFFD}" x 4 ],
    [ "\xF5\x80\x80",       "\x{FFFD}" x 3 ],
    [ "\xF5\x80\x80\x80",   "\x{FFFD}" x 4 ],
    [ "\xF6\x80\x80",       "\x{FFFD}" x 3 ],
    [ "\xF7\x80\x80",       "\x{FFFD}" x 3 ],
    [ "\xF8\x80\x80\x80",   "\x{FFFD}" x 4 ],
    [ "\xF9\x80",           "\x{FFFD}" x 2 ],
    [ "\xFA\x80",           "\x{FFFD}" x 2 ],
    [ "\xFB\x80",           "\x{FFFD}" x 2 ],
    [ "\xFC\x80",           "\x{FFFD}" x 2 ],
    [ "\xFD\x80",           "\x{FFFD}" x 2 ],
    [ "\xFE\x80",           "\x{FFFD}" x 2 ],
    [ "\xFF\x80",           "\x{FFFD}" x 2 ],
    [ "\xC2\x20\x80",       "\x{FFFD}\x20\x{FFFD}" ],
    [ "\xDF\x20\x80",       "\x{FFFD}\x20\x{FFFD}"],
    [ "\xE0\xA0\x20",       "\x{FFFD}\x20" ],
    [ "\xEF\x80\x20",       "\x{FFFD}\x20" ],
    [ "\xF0\x90\x20\x80",   "\x{FFFD}\x20\x{FFFD}" ],
    [ "\xF4\x80\x20\x80",   "\x{FFFD}\x20\x{FFFD}" ],
);

# \xE0 [\xA0-\xBF]
for my $o (0xA0..0xBF) {
    push @tests, [ pack('C2', 0xE0, $o), "\x{FFFD}" ];
}
for my $o (0x00..0x9F, 0xC0..0xFF) {
    push @tests, [ pack('C2', 0xE0, $o),
                   pack('U2', 0xFFFD, $o < 0x80 ? $o : 0xFFFD) ];
}

# \xED [\x80-\x9F]
for my $o (0x80..0x9F) {
    push @tests, [ pack('C2', 0xED, $o), "\x{FFFD}" ];
}
for my $o (0x00..0x7F, 0xA0..0xFF) {
    push @tests, [ pack('C2', 0xED, $o),
                   pack('U2', 0xFFFD, $o < 0x80 ? $o : 0xFFFD) ];
}

# \xF0 [\x90-\xBF]
for my $o (0x90..0xBF) {
    push @tests, [ pack('C2', 0xF0, $o), "\x{FFFD}" ];
}
for my $o (0x00..0x8F, 0xC0..0xFF) {
    push @tests, [ pack('C2', 0xF0, $o),
                   pack('U2', 0xFFFD, $o < 0x80 ? $o : 0xFFFD) ];
}

# \xF4 [\x80-\x8F]
for my $o (0x80..0x8F) {
    push @tests, [ pack('C2', 0xF4, $o), "\x{FFFD}" ];
}
for my $o (0x00..0x7F, 0x90..0xFF) {
    push @tests, [ pack('C2', 0xF4, $o),
                   pack('U2', 0xFFFD, $o < 0x80 ? $o : 0xFFFD) ];
}

for (my $i = 0x80; $i < 0x10FFFF; $i += 0x1000) {
    my $octets = pack_utf8($i);
    push @tests, [ substr($octets, 0, -1), "\x{FFFD}" ];
    push @tests, [ substr($octets, 1),     "\x{FFFD}" x (length($octets) - 1) ];
}

foreach my $test (@tests) {
    my ($octets, $exp) = @$test;

    my $got = do {
        no warnings 'utf8';
        decode_utf8($octets);
    };

    my $name = sprintf 'decode_utf8(<%s>) eq <%s>',
      join(' ', map { sprintf '%.2X', ord } split //, $octets),
      join(' ', map { sprintf '%.4X', ord } split //, $exp);

    is($got, $exp, $name);
}

