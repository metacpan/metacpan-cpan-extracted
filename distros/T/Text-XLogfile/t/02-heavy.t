use strict;
use warnings;
use Test::More tests => 2;
use Text::XLogfile ':all';

my $fastest_xlogline = 'crga0=Wiz Elf Fem Cha:deathlev=-5:num=204:unsure=0:points=896462:gold=740:turns=15494:align0=Cha:race=Elf:endtime=204:kills=697:deathdnum=7:death=ascended:gender=Fem:conduct=180:maxhp=107:hp=107:uid=1031:align=Cha:version=3.4.3:deaths=0:birthdate=20070601:name=Eidolos:ascended=1:deathdate=20070601:gender0=Fem:maxlvl=47:role=Wiz:conducts=2:dumplog=Eidolos.20070601-053502.txt';

my $fastest_hash = {
    align     => 'Cha',
    align0    => 'Cha',
    ascended  => 1,
    birthdate => 20070601,
    conduct   => 180,
    conducts  => 2,
    crga0     => 'Wiz Elf Fem Cha',
    death     => 'ascended',
    deathdate => 20070601,
    deathdnum => 7,
    deathlev  => -5,
    deaths    => 0,
    dumplog   => 'Eidolos.20070601-053502.txt',
    endtime   => 204,
    gender    => 'Fem',
    gender0   => 'Fem',
    gold      => 740,
    hp        => 107,
    kills     => 697,
    maxhp     => 107,
    maxlvl    => 47,
    name      => 'Eidolos',
    num       => 204,
    points    => 896462,
    race      => 'Elf',
    role      => 'Wiz',
    turns     => 15494,
    uid       => 1031,
    unsure    => 0,
    version   => '3.4.3',
};

my $fastest_h2x =  make_xlogline($fastest_hash);
my $fastest_x2h = parse_xlogline($fastest_xlogline);

my @fields_x = sort split /:/, $fastest_xlogline;
my @fields_h = sort split /:/, $fastest_h2x;

is_deeply(\@fields_x, \@fields_h, "same fields out of make_xlogline");
is_deeply($fastest_hash, $fastest_x2h, "same fields out of parse_xlogline");

