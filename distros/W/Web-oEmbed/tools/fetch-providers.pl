#!/usr/bin/perl
use strict;
use JSON::XS;
use Web::Scraper;
use URI;

sub extract_url { (m!(http://\S*)!)[0] }

my $uri = URI->new( shift || "http://www.oembed.com/" );

my $scraper = scraper {
    process "//h3[contains(text(), 'Providers')]/following-sibling::ul", 'providers[]' => scraper {
        process "//li[contains(text(), 'URL scheme')]", url => [ 'TEXT', \&extract_url ];
        process "//li[contains(text(), 'endpoint') or contains(text(), 'Endpoint')]", api => [ 'TEXT', \&extract_url ];
    };
    result 'providers';
};

my @providers = grep { defined $_->{url} } @{ $scraper->scrape($uri) };
print encode_json(\@providers);



