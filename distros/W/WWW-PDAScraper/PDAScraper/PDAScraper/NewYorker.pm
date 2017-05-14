package WWW::PDAScraper::NewYorker;

# PDAScraper.pm rules for scraping the
# NewYorker website

sub config {
    return {
        name => 'New Yorker',
        # Name of the website. Arbitrary text.

        start_from => 'http://www.newyorker.com/',
        # URL where the scraper should find the links.

         url_regex => [
            '^/([^/]+)/\D+(\d+\D+\d*)$',
            sub { \ "/printables/$1/$2" }
        ],
        
        link_spec => [sub { $_[0]->as_text ne 'archive' 
        && $_[0]->as_text ne 'The Hard Drive'
        && $_[0]->attr( 'href' ) !~ /captioncontest/ }],

        chunk_regex => qr{<table width="100%" class="indexes" cellspacing="0" cellpadding="0" border="0">(.*?)<div class="cartoonunit">}s
        
    };
}

1;
