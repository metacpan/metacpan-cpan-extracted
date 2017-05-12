#!/usr/bin/perl
use XML::DT;
use Data::Dumper;
print Dumper(MMAPON('name'));
%handler = ( contacts => sub{ [ split(";",$c)] },
             -default => sub{$c},
             -type    => { institution => 'MAP',
                           degrees     => MMAPON('name'),
                           tels        => 'SEQ' });

$a = dt(shift, %handler);

print Dumper($a);
