use Test::More tests => 11;
BEGIN { use_ok('WWW::Search') }

my $search = new WWW::Search('HGNC');

$search->native_query( 12403 );

my $prot = $search->next_result;
ok( $prot, 'got protein 12403' );

SKIP: {
  skip "couldn't fetch protein" => 7 unless $prot;

  is( $prot->{approved_symbol}, 'TTN', 'approved_symbol' );
  is( $prot->{approved_name}, 'titin', 'approved_name' );
  is( $prot->{hgnc_id}, 'HGNC:12403', 'hgnc_id' );
  is( $prot->{status}, 'Approved', 'status' );
  is( $prot->{chromosome}, '2q31', 'chromosome' );
  is( $prot->{previous_symbols}->[0], 'CMD1G', 'previous_symbols' );
  is( $prot->{gdb_id}, 'GDB:127867', 'gdb_id' );
};

$search->native_query( 1582 );
$prot = $search->next_result;
ok( $prot, 'got protein 1582' );

SKIP: {
  skip "couldn't fetch protein 1582" => 1 unless $prot;
  
  is( $prot->{approved_symbol}, 'CCND1', 'approved_symbol' );
};