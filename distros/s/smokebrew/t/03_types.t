package Test::Types;

use Moose;
use App::SmokeBrew::Types qw[PerlVersion ArrayRefUri ArrayRefStr];

has 'version' => (
  is => 'ro',
  isa => 'PerlVersion',
  coerce => 1,
);

has 'mirrors' => (
  is => 'ro',
  isa => 'ArrayRefUri',
  coerce => 1,
  auto_deref => 1,
);

has 'perlargs' => (
  is => 'ro',
  isa => 'ArrayRefStr',
  coerce => 1,
);

no Moose;

package main;
use strict;
use warnings;
use Test::More qw[no_plan];

{
  my $obj = Test::Types->new();
  isa_ok( $obj, 'Test::Types' );
}

###############
# PerlVersion #
###############

{
  my $obj = Test::Types->new( version => '5.12.0' );
  isa_ok( $obj, 'Test::Types' );
  isa_ok( $obj->version, 'Perl::Version' );
  is( $obj->version->normal, 'v5.12.0', 'The perl version is correct' );
}

{
  eval {
    my $obj = Test::Types->new( version => '6.10.0' );
  };
  like( $@, qr/The version \(6.10.0\) given is not a valid Perl version/s, 'Validated the perl version' );
}

{
  eval {
    my $obj = Test::Types->new( version => '5.005_03' );
  };
  like( $@, qr/The version \(5.005_03\) given is not a valid Perl version/s, 'Validated the perl version' );
}

###############
# ArrayRefUri #
###############

{
  my $obj = Test::Types->new( mirrors => 'http://www.cpan.org/' );
  isa_ok( $_, 'URI' ) for $obj->mirrors;
}

{
  my $obj = Test::Types->new( mirrors => [ 'http://www.cpan.org/', 'ftp://ftp.funet.fi/pub/CPAN/' ] );
  isa_ok( $_, 'URI' ) for $obj->mirrors;
}

############
# perlargs #
############

{
  my $obj = Test::Types->new( perlargs => '-Dusemallocwrap=y' );
  is( ref $obj->perlargs, 'ARRAY', 'It was coerced to an arrayref' );
}
