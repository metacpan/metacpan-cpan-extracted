#!/usr/bin/perl
use XML::DT;
%handler = ( contacts => sub{ [ split(";",$c)] },
             -default => sub{$c},
             -type    => { institution => 'MAP',
                           tels        => 'SEQ' });

$a = dt("ex10.2.xml", %handler);

use Data::Dumper;
print Dumper($a);
