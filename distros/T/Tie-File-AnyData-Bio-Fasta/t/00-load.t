#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Tie::File::AnyData::Bio::Fasta' );
}

diag( "Testing Tie::File::AnyData::Bio::Fasta $Tie::File::AnyData::Bio::Fasta::VERSION, Perl $], $^X" );
