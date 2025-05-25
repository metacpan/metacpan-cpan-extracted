#!perl
BEGIN
{
    use lib qw( ./blib/lib ./blib/arch ./lib ./t/lib );
    use Test::More;
    unless( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} )
    {
        plan(skip_all => 'These tests are for author or release candidate testing');
    }
};

eval "use Test::Pod::Coverage 1.04; use Pod::Coverage::TrustPod;";
plan( skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" ) if( $@ );
my $params =
{
    coverage_class => 'Pod::Coverage::TrustPod',
    trustme => [qr/^(bump_level|disarm_temp|double_return|first_multideref_type|parent_op_name|want_uplevel|wantarray_up)$/]
};
all_pod_coverage_ok( $params );
