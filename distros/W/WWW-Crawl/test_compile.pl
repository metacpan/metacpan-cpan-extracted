use strict;
use warnings;
use WWW::Crawl::Chromium;

eval {
    my $crawler_default = WWW::Crawl::Chromium->new();
    print "Default instantiation: OK\n";
};
if ($@) {
    print "Default instantiation: FAILED - $@\n";
}

eval {
    my $crawler_proxy = WWW::Crawl::Chromium->new(
        proxy => 'http://example.com:8080'
    );
    print "Proxy instantiation: OK\n";
};
if ($@) {
    print "Proxy instantiation: FAILED - $@\n";
}
