#!/usr/bin/perl 
use strict;
use warnings;
use Tool::Bench;
my $bench = Tool::Bench->new();
$bench->add_items( true   => sub{1}, 
                   false  => sub{0},
                   more   => { code => sub{sleep(1)},                                                                                     
                               note => 'taking a nap',
                             },
                 );
$bench->run(3);
print $bench->report;

