use common::sense;
use WWW::WTF::Testcase;

my $test = WWW::WTF::Testcase->new();

$test->run_test(sub {
    my ($self) = @_;

    my $iterator = $self->ua_lwp->recurse($self->uri_for('/sitemap.xml'));

    while (my $http_resource = $iterator->next) {
        my $uri = $http_resource->request_uri;
        $test->report->diag("Checking for HTTP URIs at $uri");

        $self->run_subtest($uri, sub {
            my %http_uris;
            my %https_uris;

            foreach my $uri ($http_resource->get_links) {
                next unless (($uri->scheme // '') =~ m/^http/);

                if ($uri->scheme eq 'http') {
                    $http_uris{$uri}++;
                } else {
                    $https_uris{$uri}++;
                }
            }

            $self->report->fail("Link is HTTP: $_")
                foreach(keys(%http_uris));

            $self->report->pass("Link is HTTPS: $_")
                foreach(keys(%https_uris));
        });
    }
});
