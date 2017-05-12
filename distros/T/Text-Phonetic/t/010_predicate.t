# -*- perl -*-

# t/010_predicate.t - submodule predicate test

use Test::Most tests=>4+1;
use Test::NoWarnings;
use utf8;

use lib qw(t/lib);
use Text::Phonetic;

require "t/global.pl";

throws_ok {
    require Text::Phonetic::Fake;
    my $t1 = Text::Phonetic::Fake->new();
    is($t1->encode('hase'),'HASE');
} qr/missing/;

throws_ok {
    my $t2 = Text::Phonetic->load(algorithm => 'Fake');
    is($t2->encode('hase'),'HASE');
} qr/missing/;


my $t3 = Text::Phonetic->load(algorithm => 'Real');
is($t3->encode('hase'),'HASE','Enocde fake ok');

require Text::Phonetic::Real;
my $t4 = Text::Phonetic::Real->new();
is($t4->encode('hase'),'HASE','Enocde real ok');

