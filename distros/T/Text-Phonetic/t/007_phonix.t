# -*- perl -*-

# t/007_phonix.t - phonix test 

use Test::Most tests=>25+1;
use Test::NoWarnings;
use utf8;

use Text::Phonetic::Phonix;

require "t/global.pl";

my $phonix = Text::Phonetic::Phonix->new();

my %TEST = (
    'Müller'	=> 'M4000000',
    schneider	=> 'S5300000',
    fischer		=> 'F8000000',
    weber		=> 'W1000000',
    meyer		=> 'M0000000',
    wagner		=> 'W2500000',
    schulz		=> 'S4800000',
    becker		=> 'B2000000',
    hoffmann	=> 'H7550000',
    'schäfer'	=> 'S7000000',
    schmidt     => 'S5300000',
# testcases from Wais Module
    computer	=> 'K5130000',
    computers   => 'K5138000',
    pfeifer		=> 'F7000000',
    pfeiffer	=> 'F7000000',
    knight      => 'N3000000',
    night       => 'N3000000',
# testcases from http://www.cl.uni-heidelberg.de/~bormann/documents/phono/
# They use a sliglty different algorithm (first char is not included in
# num code here)
    wait        => 'W3000000',
    weight      => 'W3000000',
    gnome       => 'N5000000',
    noam        => 'N5000000',
    rees        => 'R8000000',
    reece       => 'R8000000',
    yaeger      => 'v2000000',   
);

isa_ok($phonix,'Text::Phonetic::Phonix');

while (my($key,$value) = each(%TEST)) {
    test_encode($phonix,$key,$value);
}
