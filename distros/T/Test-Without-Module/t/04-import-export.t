#!/usr/bin/perl -w
use Test::More tests => 3;

use_ok( 'Test::Without::Module' );

use Test::Without::Module qw( File::Temp );
no Test::Without::Module qw( File::Temp );

is_deeply( [keys %{Test::Without::Module::get_forbidden_list()}],[],"Module list is empty" );
eval { $^W = 0; require File::Temp; };
is( $@, '', "unimport" );

