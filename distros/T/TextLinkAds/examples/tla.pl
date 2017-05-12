#!/usr/bin/perl -w

use strict;
use warnings;

use TextLinkAds ();

# Get the inventory key from the command line...
my $inventory_key = $ARGV[0];
until ( defined $inventory_key && $inventory_key ) {
    print 'Please enter a Text Link Ads inventory key: ';
    chomp( $inventory_key = <> );
}


# Instantiate a new TextLinkAds object...
my $tla = TextLinkAds->new;
    
# Fetch link information from text-link-ads.com...
my @links = @{ $tla->fetch( $inventory_key ) };

# Output the data as an HTML unordered list...
print "<ul>\n";
foreach my $link ( @links ) {
    my $before = $link->{BeforeText} || '';
    my $after  = $link->{AfterText}  || '';

    print <<"END_OF_HTML";
    <li>
        $before <a href="$link->{URL}">$link->{Text}</a> $after
    </li>
END_OF_HTML
}
print '</ul>';