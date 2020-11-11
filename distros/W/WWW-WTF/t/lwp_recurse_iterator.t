use FindBin;
use lib "$FindBin::Bin/lib";
use Test2::V0 '!meta';
use WWW::WTF::Test;

my $test = WWW::WTF::Test->new();

$test->run_test(sub {
    my ($self) = @_;

    my $iterator = $self->ua_lwp->recurse($self->uri_for('/sitemap.xml'));

    my @http_resources;

    while (my $http_resource = $iterator->next) {
        push @http_resources, $http_resource;
    }

    is(scalar @http_resources, 2, 'iterator worked');
});

done_testing();
