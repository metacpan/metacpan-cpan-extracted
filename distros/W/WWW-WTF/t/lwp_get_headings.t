use FindBin;
use lib "$FindBin::Bin/lib";
use Test2::V0 '!meta';
use WWW::WTF::Test;

my $test = WWW::WTF::Test->new();

$test->run_test(sub {
    my ($self) = @_;

    my $http_resource = $self->ua_lwp->get($self->uri_for('/index.html'));

    my @headings = $http_resource->get_headings();

    is(scalar @headings, 2);
});

done_testing();
