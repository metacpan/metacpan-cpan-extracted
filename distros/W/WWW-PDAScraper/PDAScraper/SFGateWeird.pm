package WWW::PDAScraper::SFGateWeird;

# PDAScraper.pm rules for scraping the
# Foo website

sub config {
    return {
        name => 'SF Gate Weird News',
        # Name of the website. Arbitrary text.

        start_from => 'http://www.sfgate.com/news/bondage/',
        # URL where the scraper should find the links.

        url_regex => [ '$', '&type=printable' ],
        # This is the simple form of the url_regex, which
        # is used to change a regular link to a "print-friendly"
        # link. Simple because there are no backreferences 
        # neede on the RHS.

        chunk_regex => qr{<FONT FACE="Geneva,Arial,sans-serif" SIZE="2"><B>(.*?)<TD WIDTH="15">}s
        # A regular expression which returns your desired
        # chunk of the page as $1. Using chunk_spec is better.
        
    };
}

1;
