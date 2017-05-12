#!perl -T

use Test::More tests=>2;

BEGIN {
    use_ok( "Test::Pod" );
}

my $self = $INC{'Test/Pod.pm'};

pod_file_ok($self, "My own pod is OK");

