#!/usr/bin/perl

# Example of specifying custom config file location

use Web::Passwd;
my $webapp = Web::Passwd->new( PARAMS => { config => '/home/evan/webpasswd_custom.conf' } );
$webapp->run();
