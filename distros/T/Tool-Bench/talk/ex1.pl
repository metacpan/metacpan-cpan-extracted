#!/usr/bin/perl 
use strict;
use warnings;
use lib '../lib';
use Tool::Bench;
my $bench = Tool::Bench->new();                                                                                                              
$bench->add_items( true => sub{1} );
$bench->run;
print $bench->report;



