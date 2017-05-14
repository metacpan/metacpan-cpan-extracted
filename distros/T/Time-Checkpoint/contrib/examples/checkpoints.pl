#!/usr/bin/perl

use warnings;
use strict;

use lib qw{ lib };

use Time::Checkpoint;
use Data::Dumper;

sub cb { 
	print Dumper caller 0;
}

my $t = Time::Checkpoint->new( callback => \&cb );

$t->checkpoint( 'pants' );

my $foo = $t->checkpoint( 'pants' );

warn $foo."\n";

sleep 5;

$foo = $t->checkpoint( 'pants' );

warn $foo."\n";

exit 0;
