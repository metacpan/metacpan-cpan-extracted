package WWW::PDAScraper::WeeklyWorldNews;

# PDAScraper.pm rules for scraping the
# WeeklyWorldNews website

sub config {
    return {
        name => 'Weekly World News',
        # Name of the website. Arbitrary text.

        start_from => 'http://weeklyworldnews.com/news/',
        # URL where the scraper should find the links.

        url_regex => [ '$', '?printer=1' ],
        # This is the simple form of the url_regex, which
        # is used to change a regular link to a "print-friendly"
        # link. Simple because there are no backreferences 
        # neede on the RHS.

        #   url_regex => [
        #      '/id/(\d+)/',
        #      sub { \ "/toolbar.aspx?action=print&id=$1" }
        #  ],
        #  This is the complex form of the url_regex, using
        #  a sub to return because it needs to evaluate a 
        #  backreference i.e. $1, $2 etc.

        chunk_spec => [ "_tag", "table", "width", "479" ],
        # A list of arguments to HTML::Element's look_down()
        # method. This one will return an HTML::Element object
        # matching the first ID tag having the attribute
        # "id" with value "headlines".

        # If you can't use a chunk_spec, you'll have to use a
        # chunk_regex:

        #chunk_regex => qr{<table border="0" width="512">(.*?)</table>}s,
        # A regular expression which returns your desired
        # chunk of the page as $1. Using chunk_spec is better.
        
        # link_spec => [sub { $_[0]->as_text ne 'FULL STORY' }]
        # All links are grabbed from the page chunk by default,
        # but chunk_spec allows you to add HTML::Element
        # filtering, here, for example, rejecting links in the
        # form <a href="foo">FULL STORY</a>, but you could also
        # reject them on any attribute, see HTML::Element.
    };
}

1;

