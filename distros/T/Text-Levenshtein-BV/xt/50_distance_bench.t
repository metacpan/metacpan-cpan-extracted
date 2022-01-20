#!perl
use 5.006;

use strict;
use warnings;
use utf8;

use open qw(:locale);

use lib qw(
../lib/
./lib/
/Users/helmut/github/perl/Levenshtein-Simple/lib
);

#use Test::More;

use Benchmark qw(:all) ;
use Data::Dumper;

use Text::Levenshtein::BV;
use Text::Levenshtein::BVXS;
#use Text::Levenshtein::XS qw(distance);
use Text::Levenshtein::XS;
use Text::Levenshtein;
use Text::Levenshtein::Flexible;

#use Text::Levenshtein::BVmyers;
#use Text::Levenshtein::BVhyrr;
use Levenshtein::Simple;

##use Text::LevenshteinXS;
use Text::Fuzzy;

use LCS::BV;

my @data = (
  [split(//,'Chrerrplzon')],
  [split(//,'Choerephon')]
);

#my @data = (
#  [split(//,'ſhoereſhoſ')],
#  [split(//,'Choerephon')]
#);

my @strings = qw(Chrerrplzon Choerephon);
#my @strings = qw(ſhoereſhoſ Choerephon);

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

my $tf = Text::Fuzzy->new($data[0]);

#print STDERR 'S::Similarity: ',similarity(@strings),"\n";
print STDERR 'Text::Levenshtein::BV:       ',Text::Levenshtein::BV->distance(@data),"\n";
print STDERR 'Text::Levenshtein::BVXS:     ',Text::Levenshtein::BVXS::distance(@strings),"\n";
#print STDERR 'Text::Levenshtein::BV2:      ',Text::Levenshtein::BV->distance2(@data),"\n";
#print STDERR 'Text::Levenshtein::XS:       ',&Text::Levenshtein::XS::distance(@strings),"\n";
print STDERR 'Text::Levenshtein:           ',&Text::Levenshtein::distance(@strings),"\n";
print STDERR 'Text::Levenshtein::Flexible: ',&Text::Levenshtein::Flexible::levenshtein(@strings),"\n";
print STDERR 'Text::Fuzzy:                 ',$tf->distance($data[1]),"\n";
#print STDERR 'Text::LevenshteinXS:         ',&Text::LevenshteinXS::distance(@strings),"\n";


if (1) {
    cmpthese( -1, {
       'TL::BV' => sub {
            Text::Levenshtein::BV->distance(@data)
        },
       'TL::BVXS' => sub {
            Text::Levenshtein::BVXS::distance(@strings)
        },
       'Lev::Simple' => sub {
            Levenshtein::Simple->distance(@data)
        },
       'LCS::BV' => sub {
            LCS::BV->LLCS(@data)
        },
        #'TL::XS' => sub {
        #    &Text::Levenshtein::XS::distance(@strings)
        #},
       #'TLXS' => sub {
       #     &Text::LevenshteinXS::distance(@strings)
       #},
        'TL' => sub {
            &Text::Levenshtein::distance(@strings)
        },
        'TL::Flex' => sub {
            &Text::Levenshtein::Flexible::levenshtein(@strings)
        },
        'T::Fuzz' => sub {
            $tf->distance($data[1])
        },
    });
}

=pod

Text::Levenshtein::BV:       4
Text::Levenshtein::BVXS:     4
Text::Levenshtein:           4
Text::Levenshtein::Flexible: 4
Text::Fuzzy:                 5
                 Rate     TL Lev::Simple TL::BV LCS::BV T::Fuzz TL::BVXS TL::Flex
TL             6636/s     --        -78%   -95%    -96%   -100%    -100%    -100%
Lev::Simple   29537/s   345%          --   -77%    -84%    -98%     -99%     -99%
TL::BV       130326/s  1864%        341%     --    -30%    -91%     -96%     -96%
LCS::BV      187398/s  2724%        534%    44%      --    -87%     -94%     -94%
T::Fuzz     1434347/s 21514%       4756%  1001%    665%      --     -51%     -55%
TL::BVXS    2940717/s 44214%       9856%  2156%   1469%    105%       --      -8%
TL::Flex    3206187/s 48214%      10755%  2360%   1611%    124%       9%       --
