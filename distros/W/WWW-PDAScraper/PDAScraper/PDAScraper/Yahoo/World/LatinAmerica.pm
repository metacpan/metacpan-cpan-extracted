package WWW::PDAScraper::Yahoo::World::LatinAmerica;

# PDAScraper.pm rules for scraping the
# Yahoo World LatinAmerica page

sub config {
    return {
        name       => 'Yahoo World LatinAmerica',
        start_from => 'http://news.yahoo.com/i/734',
        chunk_spec => [ "_tag", "div", "id", "indexstories" ],
        url_regex => [ '$', '&printer=1' ],
        link_spec => [sub { $_[0]->attr('href') =~ m|^/s| }] 
        # Yahoo's actual stories are in a "/s/" directory.
        # making it easy to eliminate photos, javascript, 
        # external links, etc.
    };
}

1;