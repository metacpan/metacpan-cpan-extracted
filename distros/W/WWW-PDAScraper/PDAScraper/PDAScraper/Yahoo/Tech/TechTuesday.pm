package WWW::PDAScraper::Yahoo::Tech::TechTuesday;

# PDAScraper.pm rules for scraping the
# Yahoo Tech TechTuesday page

sub config {
    return {
        name       => 'Yahoo Tech TechTuesday',
        start_from => 'http://us.rd.yahoo.com/dailynews/techtuesday/technav',
        chunk_spec => [ "_tag", "div", "id", "indexstories" ],
        url_regex => [ '$', '&printer=1' ],
        link_spec => [sub { $_[0]->attr('href') =~ m|^/s| }] 
        # Yahoo's actual stories are in a "/s/" directory.
        # making it easy to eliminate photos, javascript, 
        # external links, etc.
    };
}

1;