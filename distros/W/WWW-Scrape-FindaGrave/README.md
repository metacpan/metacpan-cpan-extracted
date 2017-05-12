# WWW-Scrape-FindaGrave
Scrape the FindaGrave site

    use HTTP::Cache::Transparent;  # be nice
    use WWW::Scape::FindaGrave;

    HTTP::Cache::Transparent::init({
    	BasePath => '/var/cache/findagrave'
    });
    my $f = WWW::Scrape::FindaGrave->new({
    	firstname => 'John',
    	lastname => 'Smith',
    	country => 'England',
    	dod => 1862
    });

    while(my $url = $f->get_next_entry()) {
    	print "$url\n";
    }
