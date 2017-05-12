# -*- perl -*-

# t/005_koeln.t - Test koelner phonetik 

use Test::Most tests=>17+1;
use Test::NoWarnings;
use utf8;

use Text::Phonetic::Koeln;

my $cologne = Text::Phonetic::Koeln->new();

require "t/global.pl";

my %TEST = (
    Wikipedia               => 3412,
    'Müller-Lüdenscheidt'   => 65752682,
    Breschnew               => 17863,
    'Müller'                => 657,
    schmidt                 => 862,
    schneider               => 8627,
    fischer                 => 387,
    weber                   => 317,
    meyer                   => 67,
    wagner                  => 3467,
    schulz                  => 858,
    becker                  => 147,
    hoffmann                => 36,
    schäfer                 => 837,
    cater                   => 427,
    axel                    => '0485',
);

isa_ok($cologne,'Text::Phonetic::Koeln');
while (my($key,$value) = each(%TEST)) {
    test_encode($cologne,$key,$value);
}





