package main;

use strict;
use warnings;

use Test::More 0.88;

BEGIN {

    eval {
	require ExtUtils::Manifest;
	ExtUtils::Manifest->import( qw{ maniread } );
	1;
    } or do {
	plan skip_all => 'ExtUtils::Manifest required.';
    };

}

my $manifest = maniread ();

my @check;
foreach ( sort keys %{ $manifest } ) {
    m/ \A bin \b /smx and next;
    m/ \A eg \b /smx and next;
    push @check, $_;
}

foreach my $file (@check) {
    open (my $fh, '<', $file) or die "Unable to open $file: $!\n";
    local $_ = <$fh>;
    close $fh;
    my @stat = stat $file;
    my $executable = $stat[2] & oct( 111 ) || m/ \A \# ! .* perl /smx;
    ok !$executable, "File $file is not executable";
}

done_testing;

1;
