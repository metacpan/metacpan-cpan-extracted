#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
use  Tvh::Htsp::Client;
my $htsp = Tvh::Htsp::Client->new( { host => 'localhost', port => 9982, debug_info => 0, no_client => 1 } );
ok( defined $htsp, "new() returned '$htsp'" );
ok( $htsp->isa('Tvh::Htsp::Client'), "and it's the 'Tvh::Htsp::Client' class" );
