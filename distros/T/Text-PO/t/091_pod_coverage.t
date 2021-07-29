#!perl
BEGIN
{
    use Test::More;
	unless( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} )
	{
		plan(skip_all => 'These tests are for author or release candidate testing');
	}
};

eval "use Test::Pod::Coverage 1.04";
plan( skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" ) if( $@ );
my $trustme = { trustme => [qr/^(init|added|character|encode|eot|from_character|from_hex|from_string|join_string|null|null_terminate|number_to_s)$/] };
all_pod_coverage_ok( $trustme );
