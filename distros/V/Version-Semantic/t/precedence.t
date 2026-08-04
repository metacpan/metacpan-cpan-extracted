use Test2::V1
  -pragmas,
  -target => { CLASS => 'Version::Semantic' },
  qw( cmp_ok ok plan subtest );

plan 3;

subtest '11.2' => sub {
  plan 3;

  my @versions = qw(
    1.0.0
    2.0.0
    2.1.0
    2.1.1
  );
  for ( my $i = 0 ; $i < $#versions ; ++$i ) {
    ok CLASS->parse( $versions[ $i ] ) < CLASS->parse( $versions[ $i + 1 ] ), "$versions[ $i ] < $versions[ $i + 1 ]"
  }
};

subtest '11.3' => sub {
  plan 3;

  my @tests = ( [ '1.0.0-alpha', '<', '1.0.0' ], [ '1.0.0', '==', '1.0.0' ], [ '1.0.0', '>', '1.0.0-alpha' ] );
  for ( @tests ) {
    my ( $l, $o, $r ) = @$_;
    cmp_ok CLASS->parse( $l ), $o, CLASS->parse( $r ), "$l $o $r"
  }
};

subtest '11.4' => sub {
  plan 21;

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
    ok CLASS->parse( $versions[ $i ] ) < CLASS->parse( $versions[ $i + 1 ] ), "$versions[ $i ] < $versions[ $i + 1 ]"
  }
  ok CLASS->parse( '1.0.0-alpha.beta' ) > CLASS->parse( '1.0.0-alpha.1' ), '1.0.0-alpha.beta > 1.0.0-alpha.1';
  ok CLASS->parse( '1.0.0-beta' ) > CLASS->parse( '1.0.0-alpha' ),         '1.0.0-beta > 1.0.0-alpha';
  ok CLASS->parse( '1.0.0-alpha' ) == CLASS->parse( '1.0.0-alpha' ),
    '1.0.0-alpha == 1.0.0-alpha (same pre-release lists)';
  ok CLASS->parse( '1.0.0-5' ) == CLASS->parse( '1.0.0-5' ), '1.0.0-5 == 1.0.0-5 (same pre-release lists)';
  ok CLASS->parse( '1.0.8-20260216170758-TRIAL' ) < CLASS->parse( '1.0.8-20260223134407-TRIAL' ),
'1.0.8-20260216170758-TRIAL < 1.0.8-20260223134407-TRIAL; lexical order matches chronological order if the date format is numeric %Y%m%d%H%M%S';
  ok CLASS->parse( '5.3.0-20260307100725-TRIAL' ) < CLASS->parse( '5.3.0-TRIAL3' ),
    '5.3.0-20260307100725-TRIAL < 5.3.0-TRIAL3';
  ok CLASS->parse( '5.3.0-20260307100725.TRIAL' ) < CLASS->parse( '5.3.0-TRIAL3' ),
'5.3.0-20260307100725.TRIAL < 5.3.0-TRIAL3; numeric identifiers (20260307100725) always have lower precedence than non-numeric identifiers (TRIAL3)'
}
