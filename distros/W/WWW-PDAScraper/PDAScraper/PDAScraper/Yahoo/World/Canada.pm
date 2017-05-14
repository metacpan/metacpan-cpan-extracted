package WWW::PDAScraper::Yahoo::World::Canada;

# PDAScraper.pm rules for scraping the
# Yahoo World Canada page

sub config {
    return {
        name       => 'Yahoo World Canada',
        start_from => 'http://us.lrd.yahoo.com/_ylt=AtfFoyDDUSGNPRG7e4XqaIBvaA8F',
        chunk_spec => [ "_tag", "div", "id", "indexstories" ],
        url_regex => [ '$', '&printer=1' ],
        link_spec => [sub { $_[0]->attr('href') =~ m|^/s| }] 
        # Yahoo's actual stories are in a "/s/" directory.
        # making it easy to eliminate photos, javascript, 
        # external links, etc.
    };
}

1;