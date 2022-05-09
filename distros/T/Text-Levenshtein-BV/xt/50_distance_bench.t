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
version 0.06
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

version 0.07 'elsif'

                 Rate     TL Lev::Simple TL::BV LCS::BV T::Fuzz TL::BVXS TL::Flex
TL             5999/s     --        -79%   -95%    -97%   -100%    -100%    -100%
Lev::Simple   28980/s   383%          --   -77%    -84%    -98%     -99%     -99%
TL::BV       124842/s  1981%        331%     --    -33%    -91%     -96%     -96%
LCS::BV      185579/s  2993%        540%    49%      --    -87%     -93%     -94%
T::Fuzz     1402911/s 23285%       4741%  1024%    656%      --     -50%     -55%
TL::BVXS    2831802/s 47104%       9672%  2168%   1426%    102%       --      -9%
TL::Flex    3113701/s 51803%      10644%  2394%   1578%    122%      10%       --

                 Rate     TL Lev::Simple TL::BV LCS::BV T::Fuzz TL::BVXS TL::Flex
TL             6515/s     --        -79%   -95%    -97%   -100%    -100%    -100%
Lev::Simple   30351/s   366%          --   -76%    -84%    -98%     -99%     -99%
TL::BV       129152/s  1882%        326%     --    -34%    -91%     -96%     -96%
LCS::BV      194606/s  2887%        541%    51%      --    -86%     -93%     -94%
T::Fuzz     1379705/s 21076%       4446%   968%    609%      --     -53%     -54%
TL::BVXS    2940717/s 45034%       9589%  2177%   1411%    113%       --      -2%
TL::Flex    2998379/s 45919%       9779%  2222%   1441%    117%       2%       --

'mask per table'
                 Rate     TL Lev::Simple TL::BV LCS::BV T::Fuzz TL::BVXS TL::Flex
TL             6636/s     --        -78%   -95%    -97%   -100%    -100%    -100%
Lev::Simple   30075/s   353%          --   -78%    -85%    -98%     -99%     -99%
TL::BV       137845/s  1977%        358%     --    -30%    -90%     -95%     -96%
LCS::BV      196495/s  2861%        553%    43%      --    -86%     -94%     -94%
T::Fuzz     1420284/s 21302%       4622%   930%    623%      --     -53%     -56%
TL::BVXS    3028065/s 45530%       9968%  2097%   1441%    113%       --      -6%
TL::Flex    3215551/s 48355%      10592%  2233%   1536%    126%       6%       --

perl 5.32.0
                  Rate      TL Lev::Simple TL::BV LCS::BV T::Fuzz TL::Flex TL::BVXS
TL              6826/s      --        -83%   -96%    -97%    -99%    -100%    -100%
Lev::Simple    40573/s    494%          --   -77%    -84%    -97%     -99%    -100%
TL::BV        173769/s   2446%        328%     --    -32%    -87%     -95%     -99%
LCS::BV       254485/s   3628%        527%    46%      --    -80%     -93%     -98%
T::Fuzz      1291788/s  18825%       3084%   643%    408%      --     -66%     -89%
TL::Flex     3814985/s  55791%       9303%  2095%   1399%    195%       --     -69%
TL::BVXS    12287999/s 179925%      30186%  6971%   4729%    851%     222%       --

BVXS ascii

                  Rate      TL Lev::Simple TL::BV LCS::BV T::Fuzz TL::Flex TL::BVXS
TL              6576/s      --        -79%   -95%    -97%   -100%    -100%    -100%
Lev::Simple    30632/s    366%          --   -78%    -84%    -98%     -99%    -100%
TL::BV        138400/s   2005%        352%     --    -28%    -90%     -96%     -99%
LCS::BV       190934/s   2803%        523%    38%      --    -86%     -94%     -98%
T::Fuzz      1377633/s  20849%       4397%   895%    622%      --     -56%     -88%
TL::Flex     3099675/s  47035%      10019%  2140%   1523%    125%       --     -72%
TL::BVXS    11062957/s 168129%      36015%  7893%   5694%    703%     257%       --


