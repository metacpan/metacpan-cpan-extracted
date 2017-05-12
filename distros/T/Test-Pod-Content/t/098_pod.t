use Test::More;

if ( not $ENV{RELEASE_TESTING} ) {
    my $msg = 'Author test.  Set $ENV{RELEASE_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

my @dir_from = ();
if (!$ENV{HARNESS_ACTIVE}) {
    # perl Build test or make test run from top-level dir.
    if ( -d '../t/' ) {
        @dir_from = ('../lib/');
    }
}

my @files = all_pod_files(@dir_from);

plan tests => scalar(@files);

foreach my $module (@files){
    pod_file_ok( $module )
}
