# -*- perl -*-

# t/006_daitchmokotoff.t - daitchmokotoff test 

use Test::Most tests=>27+1;
use Test::NoWarnings;
use utf8;

use Text::Phonetic::DaitchMokotoff;

require "t/global.pl";

my $dm = Text::Phonetic::DaitchMokotoff->new();

my %TEST = (
    ALPERT      => ['087930'],
    BREUER      => ['791900'],
    HABER       => ['579000'],
    MANHEIM     => ['665600'],
    MINTZ       => ['664000'],
    TOPF        => ['370000'],
    KLEINMAN    => ['586660'],
    SZLAMAVITZ  => ['486740'],
    SHLAMOWICZ  => ['486740'],
    AUERBACH    => ['097500','097400'],
    OHRBAC      => ['097500','097400'],
    LIPSHITZ    => ['874400'],
    LIPPSZYC    => ['874500','874400'],
    'Müller'    => ['689000'],
    schmidt     => ['463000'],
    schneider   => ['463900'],
    fischer     => ['749000'],
    weber       => ['779000'],
    meyer       => ['619000'],
    wagner      => ['756900'],
    schulz      => ['484000'],
    becker      => ['749000','745900'],
    hoffmann    => ['576600'],
    schäfer     => ['479000'],
);

isa_ok($dm,'Text::Phonetic::DaitchMokotoff');
while (my($key,$value) = each(%TEST)) {
	test_encode($dm,$key,$value);
}

is($dm->compare('LIPSHITZ','LIPPSZYC'),50);
is($dm->compare('Hase','Bär'),0);
