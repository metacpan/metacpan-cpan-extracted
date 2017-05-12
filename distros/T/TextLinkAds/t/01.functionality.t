#!perl -w

use strict;
use warnings;

use Test::More tests => 1;
use TextLinkAds;

diag <<"END_OF_DIAG";

Testing the functionality of this module requires a network connection and a
working text-link-ads.com account. To skip this test just press return,
otherwise enter a valid XML key below...
END_OF_DIAG
chomp( my $inventory_key = <> );

SKIP: {
    skip 'XML key not provided', 1 unless $inventory_key;
        
    my $tla = TextLinkAds->new({ cache => 0 });
    
    # Fetch link information from text-link-ads.com...
    my @links = @{ $tla->fetch( $inventory_key ) };
    
    # Output the data in some meaningful way...
    diag "\n<ul>\n";
    foreach my $link ( @links ) {
        my $before = $link->{BeforeText} || '';
        my $after  = $link->{AfterText}  || '';

        diag <<"END_OF_HTML";
        <li>
            $before <a href="$link->{URL}">$link->{Text}</a> $after
        </li>
END_OF_HTML
    }
    diag '</ul>';
    
    # Check with the user whether or not the data looks right...
    diag "\nDoes the above look right to you? (Y/n)";
    chomp( my $pass = <> );
    !$pass || $pass =~ /^y/i ? pass('Valid data from Text Link Ads')
                             : fail('Valid data from Text Link Ads');
    
    # Tidy up...
    unlink "$tla->{tmpdir}/tla_$inventory_key";
}
