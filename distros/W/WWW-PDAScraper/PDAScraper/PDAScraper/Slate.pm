package WWW::PDAScraper::Slate;

# PDAScraper.pm rules for scraping the
# Slate website

sub config {
    return {
        name       => 'Slate',
        start_from =>
          'http://www.slate.com/id/2065896/view/2057069/',
        url_regex => [
            '/id/(\d+)/',
            sub { \ "/toolbar.aspx?action=print&id=$1" }
        ],
        chunk_regex =>
          qr{</p></td></tr></table>(.*?)<img[^>]+SlateonNPR.gif}
    };
}

1;

