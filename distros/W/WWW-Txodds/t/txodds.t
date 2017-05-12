#!/usr/bin/env perl

use Test::More tests => 3;
use WWW::Txodds;

my $tx = WWW::Txodds->new();

note 'Action parse_xml';

my $xml;
while (<DATA>) {
    $xml .= $_;
}

my $obj = $tx->parse_xml( $xml, ForceArray => 'bookmaker' );
isa_ok $obj, 'HASH', 'XML response ok';
is $obj->{match}->{1580242}->{bookmaker}->{'betPro.it'}->{offer}->{78067510}
  ->{odds}->[0]->{o1}, 2.62, '1 node OK';
is $obj->{match}->{1583309}->{group}->{8925}->{content},
  'TENNIS Open de Moselle-11', '2 node OK';


__DATA__
<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<matches time="2011-09-23T12:30:07+00:00" timestamp="1316781007">
    <match id="1580242" xsid="0">
    <time>2011-09-23T12:00:00+00:00</time>
    <group id="8925">TENNIS Open de Moselle-11</group>
    <hteam id="7736">Sijsling, Igor</hteam>
    <ateam id="3563">Ljubicic, Ivan</ateam>
    <results>
    </results>
    <bookmaker bid="474" name="betPro.it">
        <offer id="78067510" n="1" ot="0" last_updated="2011-09-23T12:02:44+00:00" flags="0" bmoid="0">
            <odds i="0" time="2011-09-23T09:36:40+00:00" starting_time="2011-09-23T11:13:00+00:00">
                <o1>2.62</o1>
                <o2>1.45</o2>
                <o3>4</o3>
            </odds>
        </offer>
    </bookmaker>
    </match>
    <match id="1583309" xsid="0">
        <time>2011-09-23T14:00:00+00:00</time>
        <group id="8925">TENNIS Open de Moselle-11</group>
        <hteam id="4941">Muller, Gilles</hteam>
        <ateam id="4884">Gasquet, Richard</ateam>
        
        <results>
        </results>
        <bookmaker bid="474" name="betPro.it">
            <offer id="78067511" n="1" ot="0" last_updated="2011-09-23T12:26:43+00:00" flags="1" bmoid="0">
                <odds i="0" time="2011-09-23T09:36:40+00:00" starting_time="2011-09-23T13:15:00+00:00">
                    <o1>3.3</o1>
                    <o2>1.3</o2>
                    <o3>5.8</o3>
                </odds>
            </offer>
        </bookmaker>
    </match>
</matches>
