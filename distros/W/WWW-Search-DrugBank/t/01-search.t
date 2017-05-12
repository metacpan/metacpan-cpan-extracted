use Test::More tests => 4;
BEGIN { use_ok( 'WWW::Search' ) }

my $search = new WWW::Search('DrugBank');
$search->native_query( 'APRD00109' );

my $drug = $search->next_result;
ok( $drug, 'fetch drug APRD00109' );
is( $drug->{accession_number}, 'DB00328', 'accession number' );

SKIP: {
  skip "couldn't fetch drug" => 1 unless $drug;
  is( $drug->{generic_name}, 'Indomethacin', 'generic name' );
}
