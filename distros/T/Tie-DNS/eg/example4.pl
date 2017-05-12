#!/usr/bin/perl -w

use strict;use warnings;
use Tie::DNS;

my $type = shift or die("lookup type required.");

#this is my local domain.  Put a domain in that you have zone transfer
#access to.
tie(
    %dns,
    'Tie::DNS',
    {
        'Domain'   => 'realms.lan',
        'multiple' => 'true',
        'type'     => $type
    }
);

print "Enter names to lookup.  Enter EOF to end.\n";

while (<>) {
    chomp;
    my $result_ref = $dns{$_};
    if ( ( scalar @{$result_ref} ) > 0 ) {
        foreach ( @{$result_ref} ) {
            print "	$_\n";
        }
    }
    else {
        print 'No result: ' . tied(%dns)->error . "\n";
    }
}
