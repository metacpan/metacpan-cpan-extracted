# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 5;
# ----------------------------------------------------------------
{
	use_ok('XML::OverHTTP');

	my $ver = $XML::TreePP::VERSION;
	ok( ($ver > 0.23), "XML::TreePP $ver" );

    my $api = XML::OverHTTP->new();
	my $tpp = $api->treepp();
	ok( ref $tpp, 'treepp' );
	$tpp->set( utf8_flag => 1 );
	is( $api->treepp()->get( 'utf8_flag' ), 1, 'utf8_flag: true' );
	$tpp->set( utf8_flag => 0 );
	is( $api->treepp()->get( 'utf8_flag' ), 0, 'utf8_flag: false' );
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
