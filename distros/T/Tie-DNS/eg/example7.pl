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
        'domain'   => 'realms.lan',
        'multiple' => 'true',
        'type'     => $type
    }
);

$dns{'food.realms.lan.'} = '131.22.40.1';

foreach ( @{ $dns{'brain'} } ) {
    print "	$_\n";
}
