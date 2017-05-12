#!/usr/bin/perl 
use strict;
use warnings;
use Tool::Bench;
my $bench = Tool::Bench->new();
my $naptime;
$bench->add_items( true   => sub{1}, 
                   false  => sub{0},
                   more   => { code     => sub{sleep($naptime)},
                               note     => 'taking a nap',
                               buildup  => sub{$naptime = rand(10)},
                               teardown => sub{$naptime = 1},
                             },
                 );
$bench->run(3);
print $bench->report(format => 'JSON'); 
