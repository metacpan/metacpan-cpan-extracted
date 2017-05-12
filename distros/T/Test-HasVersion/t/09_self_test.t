
use Test::More tests => 2;

BEGIN {
    use_ok("Test::HasVersion");
}

my $self = $INC{'Test/HasVersion.pm'};
pm_version_ok( $self, "My own version is ok" );
