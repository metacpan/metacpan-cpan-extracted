package main;

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::LoadModule;

load_module_or_skip_all 'ExtUtils::Manifest', undef, [ 'maniread' ];

my $manifest = maniread();

foreach ( sort keys %{ $manifest } ) {
    m{ \A eg / }smx
	and next;
    m{ \A script / }smx
	and next;
    m{ \A tools / }smx
	and next;

    ok ! is_executable(), "$_ should not be executable";
}

done_testing;

sub is_executable {
    my @stat = stat $_;
    $stat[2] & oct(111)
	and return 1;
    open my $fh, '<', $_ or die "Unable to open $_: $!\n";
    local $_ = <$fh>;
    close $fh;
    return m{ \A [#]! .* perl }smx;
}

1;

# ex: set textwidth=72 :
