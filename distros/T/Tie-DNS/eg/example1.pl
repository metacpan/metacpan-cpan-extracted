#!/usr/bin/perl -w

use strict;use warnings;
use Tie::DNS;

#this is my local domain.  Put a domain in that you have zone transfer
#access to.
tie( %dns, 'Tie::DNS', { 'Domain' => 'realms.lan' } );

print "Enter names to lookup.  Enter EOF to end.\n";

while (<>) {
    chomp;
    my $result = $dns{$_};
    if ( defined($result) ) {
        print $result, "\n";
    }
    else {
        print 'No result: ' . tied(%dns)->error . "\n";
    }
}

foreach my $key ( keys(%dns) ) {
    print "$key\n";
}

while ( ( $name, $ip ) = each %dns ) {
    print "$name = $ip\n";
}
