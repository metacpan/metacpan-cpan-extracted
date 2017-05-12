#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

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
      out_dir => 't/boilerplate.t', perltidyrc => 't/perltidyrc',
    } ), 'can call new' );

dies_ok { $stub->gen_testfile } "Non directory in out_dir and dies";
like( $@, qr/Can't write to file 'filename\.t'/, "Permission denied to treat file as directory." );
