#!perl -Tw

use strict;

use Test::More tests => 2;

BEGIN {
    use_ok( "Test::Pod" );
}

my @expected;
if ( $^O eq "VMS" ) {
    @expected = (
        File::Spec->catfile( 'lib', 'Test', 'Pod.pm' ),
        File::Spec->catfile( 't', 'pod', 'good-pod-script.' ),
        File::Spec->catfile( 't', 'pod', 'good-pod-script.bat' ),
        File::Spec->catfile( 't', 'pod', 'good.pod' ),
        File::Spec->catfile( 't', 'pod', 'no_pod.pod' ),
    );
}
else {
    # The expected files have slashes, not File::Spec separators, because
    # that's how File::Find does it.
    @expected = qw(
        lib/Test/Pod.pm
        t/pod/good-pod-script
        t/pod/good-pod-script.bat
        t/pod/good.pod
        t/pod/no_pod.pod
    );
}
my @files = sort map { lc } all_pod_files( "lib", "t/pod" );
@expected = sort map { lc } @expected;
s{\\}{/}g for @files, @expected;
is_deeply( \@files, \@expected, "Got all the distro files" );
