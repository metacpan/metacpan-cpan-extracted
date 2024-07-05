#!/usr/bin/perl -w
use strict;
use Symbol qw( delete_package );
use Test::More tests => 6;

BEGIN { use_ok( "Test::Without::Module", qw( Digest::MD5 )); };

{
  use Test::Without::Module qw( Digest::MD5 );

  eval { require Digest::MD5 };
  use Test::Without::Module qw( Digest::MD5 );
  ok( $@ ne '', "Loading raised error");
  like( $@, qr!^(Can't locate Digest/MD5.pm in \@INC|Digest/MD5.pm did not return a true value at)!, "Hid module");
  is_deeply( [sort keys %{Test::Without::Module::get_forbidden_list()}],[ qw[ Digest/MD5.pm ]],"Module list" );
  delete_package( 'Digest::MD5' );
};

TODO: {
  local $TODO = 'Implement lexical scoping';
  eval { require 'Digest::MD5' };
  is( $@, '', "Local (require) confinement");
  delete_package( 'Digest::MD5' );
  eval q{ use Digest::MD5 };
  is( $@, '', "Local (use) confinement");
};
