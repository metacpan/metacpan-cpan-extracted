package WWW::PDAScraper::ABC;

# PDAScraper.pm rules for scraping the 
# Australian Broadcasting Corporation website

sub config {
    return {
    name       => 'ABC',
    start_from => 'http://abc.net.au/news/justin/default.htm',
    chunk_regex =>
      qr|<!-- ==== START HEADLINE/FIRST PAR FEED COLUMN. \(Wallace Generated\) ===== -->(.*?)<!-- ======== END HEADLINE/FIRST PAR FEED COLUMN ====== -->|s,
      link_spec => [sub { $_[0]->as_text ne 'FULL STORY' }],
      url_regex => [ '^', 'http://www.abc.net.au/cgi-bin/common/printfriendly.pl?' ]
};
}

1;

