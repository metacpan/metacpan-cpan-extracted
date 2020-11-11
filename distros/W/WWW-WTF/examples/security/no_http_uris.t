use common::sense;
use Test2::V0 '!meta';
use WWW::WTF::Testcase;

my $test = WWW::WTF::Testcase->new();

$test->run_test(sub {
    my ($self) = @_;

    my $iterator = $self->ua_lwp->recurse($self->uri_for('/sitemap.xml'));

    my $http_uris = {};

    while (my $http_resource = $iterator->next) {
        foreach my $uri ($http_resource->get_links) {
            if (($uri->scheme // '') eq 'http') {
                $http_uris->{$uri}++;
                next;
            }

            pass("Link is HTTPS $uri");
        }
    }

    foreach(keys(%$http_uris)) {
        fail("HTTP URI found: " . $_);
    }

    done_testing();
});
