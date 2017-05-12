#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
BEGIN {
  eval "use Test::Warn";
  plan skip_all => 'Test::Warn required for tests' if $@;
}

plan tests => 3;
use_ok( 'Test::StubGenerator' );

my $source =<<'SOURCE_END';
open( my $log, '<', shift ) or die "can't open file - $!";
while( my $line = <$log> ){
  print if m/target/;
}
SOURCE_END

ok( my $stub = Test::StubGenerator->new( { source => \$source, tidy => 0 } ),
    'can call new' );

warnings_like { $stub->gen_testfile() }
  [ { carped => qr/No packages found/ }, { carped => qr/No subs found/ }, ];
