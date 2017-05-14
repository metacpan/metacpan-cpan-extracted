#!/usr/bin/perl

use Time::Checkpoint;
use Benchmark qw{ timethese };

sub cb { 1 }

my $t  = Time::Checkpoint->new( callback => \&cb );
my $t2 = Time::Checkpoint->new( );

timethese( -30, {
	with_callback => sub { $t->cp('pie') },
	without_callback => sub { $t2->cp('pie') },
} );

exit 0;
