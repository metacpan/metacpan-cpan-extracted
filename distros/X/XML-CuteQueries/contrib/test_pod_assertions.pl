#!/usr/bin/perl

use strict;
use warnings;
use XML::CuteQueries qw(CQ);

my $xml = q(
    <root>
        <result>OK</result>
        <data a="this'll be hard to fetch I think" b="I may need special handlers for @queries">
            <row> <f1>7</f1><f2>11</f2><f3>13</f3></row>
            <row><f1>17</f1><f2>19</f2><f3>23</f3></row>
            <row><f1>29</f1><f2>31</f2><f3>37</f3></row>
        </data>
        <atad>
            <c1><f1>503</f1><f1>509</f1></c1>
            <c2><f1>521</f1><f1>523</f1></c2>
        </atad>
        <keywords>
            <hot>alpha</hot>
            <hot>beta</hot>
            <cool>psychedelic</cool>
            <cool>funky</cool>
            <loud>beat</loud>
        </keywords>
    </root>
);

CQ->parse($xml);

use Data::Dump qw(dump);
#print dump(+{ CQ->hash_query(keywords=>{'[]*'=>''}) }), "\n";

    my $hashref = CQ->cute_query(
        '.' => {
            result => '',
            data => [ row => {'*'=>''} ],
            atad => { '*' => [ '*' => ''] },
            keywords => { '[]*' => '' }
        }
    );

print dump($hashref), "\n";
