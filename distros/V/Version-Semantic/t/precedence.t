use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT cmp_ok ok plan require_ok subtest ) ], tests => 4;
my $class;

BEGIN {
  $class = 'Version::Semantic';
  require_ok $class or BAIL_OUT "Cannot load class '$class'!"
}

subtest '11.2' => sub {
  plan tests => 3;

  my @versions = qw(
    1.0.0
    2.0.0
    2.1.0
    2.1.1
  );
  for ( my $i = 0 ; $i < $#versions ; ++$i ) {
    ok $class->parse( $versions[ $i ] ) < $class->parse( $versions[ $i + 1 ] ), "$versions[ $i ] < $versions[ $i + 1 ]"
  }
};

subtest '11.3' => sub {
  plan tests => 3;

  my @tests = ( [ '1.0.0-alpha', '<', '1.0.0' ], [ '1.0.0', '==', '1.0.0' ], [ '1.0.0', '>', '1.0.0-alpha' ] );
  for ( @tests ) {
    my ( $l, $o, $r ) = @$_;
    cmp_ok $class->parse( $l ), $o, $class->parse( $r ), "$l $o $r"
  }
};

subtest '11.4' => sub {
  plan tests => 18;

  my @versions = qw(
    0.9.0
    1.0.0-alpha
    1.0.0-alpha.1
    1.0.0-alpha.beta
    1.0.0-beta
    1.0.0-beta.2
    1.0.0-beta.11
    1.0.0-beta.31
    1.0.0-beta.200
    1.0.0-beta.200.more
    1.0.0-rc.1
    1.0.0
    2.0.0
    2.1.0
    2.1.1
  );

  for ( my $i = 0 ; $i < $#versions ; ++$i ) {
    ok $class->parse( $versions[ $i ] ) < $class->parse( $versions[ $i + 1 ] ), "$versions[ $i ] < $versions[ $i + 1 ]"
  }
  ok $class->parse( '1.0.0-alpha.beta' ) > $class->parse( '1.0.0-alpha.1' ), '1.0.0-alpha.beta > 1.0.0-alpha.1';
  ok $class->parse( '1.0.0-beta' ) > $class->parse( '1.0.0-alpha' ),         '1.0.0-beta > 1.0.0-alpha';
  ok $class->parse( '1.0.0-alpha' ) == $class->parse( '1.0.0-alpha' ),
    '1.0.0-alpha == 1.0.0-alpha (same pre-release lists)';
  ok $class->parse( '1.0.0-5' ) == $class->parse( '1.0.0-5' ), '1.0.0-5 == 1.0.0-5 (same pre-release lists)'
}
