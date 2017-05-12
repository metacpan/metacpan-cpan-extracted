#!/usr/bin/perl
use XML::DT;
use Data::Dumper;
%handler = ( -default => sub{$c},
             person   => sub{ print " 
$c->{name} 
$c->{address}[0]

Dear $c->{name}
Merry Christmas from Morris\n"; $c;},
             -type    => { people => 'SEQ',
                           person => MMAPON('address')});

$people = dt("ex11.1.xml", %handler);

print Dumper($people);
print $people->[1]{address}[1];
