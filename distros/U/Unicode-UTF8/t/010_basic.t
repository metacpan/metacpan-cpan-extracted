#!perl

use strict;
use warnings;
use lib 't';

use Test::More  tests => 1366;
use Test::Fatal qw[lives_ok];
use Util        qw[pack_utf8 slurp];

BEGIN {
    use_ok('Unicode::UTF8', qw[ decode_utf8
                                encode_utf8 
                                valid_utf8 ]);
}

for (my $cp = 0x00; $cp < 0x10FFFF; $cp += 0x1000) {
    my $octets = pack_utf8($cp);
    my $string = pack('U', $cp);

    {
        my $name = sprintf 'decode_utf8(<%s>) U+%.4X',
          join(' ', map { sprintf '%.2X', ord $_ } split //, $octets), $cp;

        my $got;
        lives_ok {
            use warnings FATAL => 'utf8';
            $got = decode_utf8($octets);
        } $name;
        is($got, $string, $name);
    }

    {
        my $name = sprintf 'valid_utf8(<%s>) U+%.4X',
          join(' ', map { sprintf '%.2X', ord $_ } split //, $octets), $cp;

        ok(valid_utf8($octets), $name);
    }

    {
        my $name = sprintf 'encode_utf8("\\x{%.4X}") U+%.4X',
          $cp, $cp;

        my $got;
        lives_ok {
            use warnings FATAL => 'utf8';
            $got = encode_utf8($string);
        } $name;
        is($got, $octets, $name);
    }
}

{
    my $octets = do {
        open my $fh, '<:raw', 't/quickbrown.txt'
          or die qq<Could not open 't/quickbrown.txt': '$!'>;
        slurp($fh);
    };

    my $string = do { 
        utf8::decode(my $copy = $octets)
          or die q<Could not decode quickbrown.txt>;
        $copy;
    };

    {
        my $got;
        lives_ok { 
            use warnings FATAL => 'utf8';
            $got = decode_utf8($octets);
        } 'decode_utf8(quickbrown.txt)';
        is($got, $string, 'decode_utf8(quickbrown.txt) result');
    }

    {
        ok(valid_utf8($octets), 'valid_utf8(quickbrown.txt)');
    }

    {
        my $got;
        lives_ok { 
            use warnings FATAL => 'utf8';
            $got = encode_utf8($string);
        } 'encode_utf8(quickbrown.txt)';
        is($got, $octets, 'encode_utf8(quickbrown.txt) result');
    }
}

