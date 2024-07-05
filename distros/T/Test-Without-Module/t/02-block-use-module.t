#!/usr/bin/perl -w
use strict;

use Test::More tests => 4;

BEGIN{ use_ok( "Test::Without::Module", qw( Digest::MD5 )); };

is_deeply( [sort keys %{Test::Without::Module::get_forbidden_list()}],[ qw[ Digest/MD5.pm ]],"Module list" );
eval q{ use Digest::MD5 };
ok( $@ ne '', 'Importing raises an error' );
like( $@, qr!^(Can't locate Digest/MD5.pm in \@INC|Digest/MD5.pm did not return a true value at)!, "Hid module");
