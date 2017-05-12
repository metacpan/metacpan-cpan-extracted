use Test::More;

# rt108500
if ( !$ENV{'RELEASE_TESTING'} ) {

   plan( skip_all => "RELEASE_TESTING not set in environment" );
}

eval {

     require Test::Pod::Coverage;
};

if ( $@ ) {

   plan( skip_all => "Test::Pod::Coverage required" );
}

Test::Pod::Coverage->import();

pod_coverage_ok( 'WebService::Pandora' );
pod_coverage_ok( 'WebService::Pandora::Cryptor' );
pod_coverage_ok( 'WebService::Pandora::Method' );

# only worry about parent Partner module and not sub-classes
my $trustparents = { coverage_class => 'Pod::Coverage::CountParents' };
pod_coverage_ok( 'WebService::Pandora::Partner', $trustparents );

done_testing();