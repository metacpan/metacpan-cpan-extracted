#!perl
use 5.006;

use strict;
use warnings;
#use utf8;

use open qw(:locale);

use lib qw(../lib/);

use Benchmark qw(:all) ;

use LCS::BV;

my @data = (
  [split(//,'Chrerrplzon')],
  [split(//,'Choerephon')]
);

my @strings = qw(Chrerrplzon Choerephon);

my @data2 = (
  [split(//,'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY')],
  [split(//, 'bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')]
);

my @strings2 = qw(
abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXY
bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
);

my @data3 = ([qw/a b d/ x 50], [qw/b a d c/ x 50]);

my @strings3 = map { join('',@$_) } @data3;




if (1) {
    timethese( 100_000, {
        'LCSbv' => sub {
            LCS::BV->LCS(@data)
        },
    });
}

if (0) {
    cmpthese( 10_000, {
       'LCSidx' => sub {
            Algorithm::Diff::LCSidx(@data2)
        },
        'LCSbv' => sub {
            LCS::BV->LCS(@data2)
        },
    });
}

if (0) {
    cmpthese( 1, {
       'LCSidx' => sub {
            Algorithm::Diff::LCSidx(@data3)
        },
        'LCSbv' => sub {
            LCS::BV->LCS(@data3)
        },
    });
}



