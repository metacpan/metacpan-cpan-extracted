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
        'Domain'     => 'realms.lan',
        'multiple'   => 'true',
        'all_fields' => 'true',
        'type'       => $type
    }
);

&do_loop;
tied(%dns)->args(
    {
        'multiple'   => 'true',
        'all_fields' => 'true',
        'type'       => 'A'
    }
);
&do_loop;

sub do_loop {
    print "Enter names to lookup.  Enter EOF to end.\n";
    while (<>) {
        chomp;
        my $result_ref = $dns{$_};
        if ( ( scalar @{$result_ref} ) > 0 ) {
            foreach ( @{$result_ref} ) {
                while ( ( $field, $value ) = each %{$_} ) {
                    print "	$field = $value\n";
                }
            }
        }
        else {
            print 'No result: ' . tied(%dns)->error . "\n";
        }
    }
}
