#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan skip_all => 'Test assumes no root permission to /etc - skipping if running as root' if $> == '0';

BEGIN {
  eval "use Test::Exception";
  plan skip_all => 'Test::Exception required for tests' if $@;
}

plan tests => 4;

use_ok( 'Test::StubGenerator' );

my $filename = 'filename.t';

ok( my $stub = Test::StubGenerator->new( {
      file  => 't/inc/MyObj.pm',
      output => $filename,
      out_dir => '/etc', tidy => 0 ,
    } ), 'can call new' );

dies_ok { $stub->gen_testfile } "Non accessible directories can't be written to and dies";
like( $@, qr/Can't open file for writing:/, "Permission denied" );
