#!perl

use Test::More;

plan skip_all => "set AUTHOR_TESTING=1 to run this test" if not $ENV{AUTHOR_TESTING};

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

my $PARAMS = { also_private => [qr/^[A-Z_]+$/] };

pod_coverage_ok( 'WWW::GoDaddy::REST',             $PARAMS );
pod_coverage_ok( 'WWW::GoDaddy::REST::Collection', $PARAMS );
pod_coverage_ok( 'WWW::GoDaddy::REST::Resource',   $PARAMS );
pod_coverage_ok( 'WWW::GoDaddy::REST::Util',       $PARAMS );

TODO: {
    todo_skip "TODO: fill in POD for these modules", 1;
    pod_coverage_ok( 'WWW::GoDaddy::REST::Schema', $PARAMS );
}

done_testing();
