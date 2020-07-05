#!perl
use 5.006;

use strict;
use warnings;
#use utf8;

use open qw(:locale);

use lib qw(../lib/);

#use Test::More;

use Algorithm::Diff;
use Algorithm::Diff::XS;
use String::Similarity;
#use Algorithm::LCS;

use Benchmark qw(:all) ;
use Data::Dumper;

#use LCS::Tiny;
#use LCS;
use LCS::BV;

#my $align = Align::Sequence->new;

#my $align_bv = LCS::Tiny->new;
#my $traditional = LCS->new();

#my $A_LCS = Algorithm::LCS->new();

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

print STDERR 'S::Similarity: ',similarity(@strings),"\n";



if (1) {
    cmpthese( -1, {
       #'LCS' => sub {
            #$traditional->LCS(@data)
        #},
       'LCSidx' => sub {
            Algorithm::Diff::LCSidx(@data)
        },
        'LCSXS' => sub {
            Algorithm::Diff::XS::LCSidx(@data)
        },
        'LCSbv' => sub {
            LCS::BV->LCS(@data)
        },
        #'LCStiny' => sub {
            #LCS::Tiny->LCS(@data)
        #},
        'S::Sim' => sub {
            similarity(@strings)
        },
    });
}

if (0) {
    cmpthese( -1, {
       'LCS' => sub {
            #$traditional->LCS(@data2)
        },
       'LCSidx' => sub {
            Algorithm::Diff::LCSidx(@data2)
        },
        'LCSXS' => sub {
            Algorithm::Diff::XS::LCSidx(@data2)
        },
        'LCSbv' => sub {
            LCS::BV->LCS(@data2)
        },
        'S::Sim' => sub {
            similarity(@strings2)
        },
    });
}

if (0) {
    cmpthese( -1, {
       'LCS' => sub {
            #$traditional->LCS(@data3)
       },
       'LCSidx' => sub {
            Algorithm::Diff::LCSidx(@data3)
        },
        'LCSXS' => sub {
            Algorithm::Diff::XS::LCSidx(@data3)
        },
        'LCSbv' => sub {
            LCS::BV->LCS(@data3)
        },
        'LCStiny' => sub {
            LCS::Tiny->LCS(@data3)
        },
    });
}

if (0) {
    timethese( 100_000, {
        'S::Sim' => sub {
            similarity(@strings3)
        },
    });
}


