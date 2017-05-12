package WWW::PDAScraper::NewScientist;

# PDAScraper.pm rules for scraping the 
# New Scientist website

sub config {
    return {
        name       => 'New Scientist Headlines',
        start_from => 'http://www.newscientist.com/news.ns',
        chunk_spec => [ "_tag", "div", "class", "copycontent" ],
        url_regex => [ '$', '&print=true' ],
        encoding => 'ISO-8859-1'
    };
}

1;

