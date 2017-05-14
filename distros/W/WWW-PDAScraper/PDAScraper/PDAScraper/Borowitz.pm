package WWW::PDAScraper::Borowitz;

# PDAScraper.pm rules for scraping the
# Borowitz Report website

sub config {
    return  {
        name       => 'Borowitz Report',
        start_from =>
          'http://www.borowitzreport.com/archives.asp',
        chunk_spec => [ "_tag", "div", "id", "content2" ],
        encoding => 'ISO-8859-1'
    };
}

1;

