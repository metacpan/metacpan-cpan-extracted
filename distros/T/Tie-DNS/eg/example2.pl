#!/usr/bin/perl -w

use strict;use warnings;
use Tie::DNS;

#this is my local domain.  Put a domain in that you have zone transfer
#access to.
tie(
    %dns,
    'Tie::DNS',
    {
        'Domain'   => 'realms.lan',
        'multiple' => 'true'
    }
);

print "Enter names to lookup.  Enter EOF to end.\n";

while (<>) {
    chomp;
    my $result_ref = $dns{$_};
    if ( defined($result_ref) ) {
        foreach ( @{$result_ref} ) {
            print "	$_\n";
        }
    }
    else {
        print 'No result: ' . tied(%dns)->error . "\n";
    }
}
