use strict;
use warnings;
use utf8;
use Test::More;
use Text::Lorem::JA;

subtest 'generate sentence with 1 chain' => sub {
    my $dict = <<'END_DICT';
1

A
B
C
D

0=1
1=2
2=3,4
3=-1
4=-1
END_DICT

    my $lorem = Text::Lorem::JA->new( dictionary => \$dict, lazy => 0 );

    for (1..5) {
        like $lorem->sentence, qr{^ A B (C | D) $}xmso;
    }
};

subtest 'generate sentence with 2 chain' => sub {
    my $dict = <<'END_DICT';
2

A
B
C
D

0
 0=1
 1=2,4
1
 2=3,4
 4=2,3
2
 3=-1
 4=-1
4
 2=-1
 3=-1
END_DICT

    my $lorem = Text::Lorem::JA->new( dictionary => \$dict, lazy => 0 );

    for (1..5) {
        like $lorem->sentence, qr{^ A (B (C|D) | D (B|C) ) $}xmso;
    }
};

done_testing;

