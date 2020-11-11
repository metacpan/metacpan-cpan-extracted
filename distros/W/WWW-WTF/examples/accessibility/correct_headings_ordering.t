use common::sense;
use Test2::V0 '!meta';
use WWW::WTF::Testcase;

my $test = WWW::WTF::Testcase->new();

$test->run_test(sub {
    my ($self) = @_;

    my $iterator = $self->ua_lwp->recurse($self->uri_for('/sitemap.xml'));

    while (my $http_resource = $iterator->next) {

        my @headings = $http_resource->get_headings;
    }

    done_testing();
});
