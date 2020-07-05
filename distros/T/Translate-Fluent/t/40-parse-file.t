#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;


BEGIN {
    use_ok( 'Translate::Fluent' ) || print "Bail out!\n";
}

my $path = $0;

# test with a missing file, to see if it dies.

$path =~ s{t/40-parse-file.t}{test_files/basic-missing.flt};
eval {
  my $resource_set = Translate::Fluent::Parser::parse_file( $path );
  
  fail("should have died with a missing file");
  1;
} or do {
  ok("died when tried to read a missing file");

};

$path =~ s{\-missing}{};

my $resource_set = Translate::Fluent::Parser::parse_file( $path );
ok( $resource_set, "Defined resource_set");

BAIL_OUT("Undefined resource_set")
  unless $resource_set;

isa_ok( $resource_set, "Translate::Fluent::ResourceSet");


$path =~ s{basic.flt}{empty.flt};
my $empty_set = Translate::Fluent::Parser::parse_file( $path );
is($empty_set, undef, 'file with no definitions should return undef');

$path =~ s{empty.flt}{broken.flt};
my $broken_set = Translate::Fluent::Parser::parse_file( $path );
is($broken_set, undef, 'file with only broken definitions should return undef');

done_testing();
