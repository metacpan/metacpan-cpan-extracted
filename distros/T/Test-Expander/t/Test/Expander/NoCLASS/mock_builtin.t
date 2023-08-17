use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Builder::Tester tests => 1;

use FindBin;
use lib "$FindBin::Bin/../../../..";

my $title = "mock 'close'";
use Test::Expander
  -builtins => { close => sub { $title } },
  -method   => 'my_func',
  -target   => 't::Test::Expander::NoCLASS::MyModule';

test_out( "ok 1 - $title" );
is( $METHOD_REF->(), $title, $title );
test_test( $title );

done_testing();
