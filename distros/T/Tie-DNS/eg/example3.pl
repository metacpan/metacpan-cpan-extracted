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

while ( ( $name, $ip_ref ) = each %dns ) {
    print "$name = \n";
    foreach ( @{$ip_ref} ) {
        print "	$_\n";
    }
}
