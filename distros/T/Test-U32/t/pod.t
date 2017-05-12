use Test;

#$ENV{RELEASE_TESTING}++;

eval "use Test::Pod 1.00";

if ($@) {
    print "1..0 # Skip Test::Pod 1.00 required for testing POD\n";
}
else {
    if ( $ENV{RELEASE_TESTING} ) {
        my @poddirs = qw(lib ../lib);
        all_pod_files_ok(all_pod_files( @poddirs ));
    }
    else {
        print "1..0 # Skip Author only pod tests not required\n";
    }
}
