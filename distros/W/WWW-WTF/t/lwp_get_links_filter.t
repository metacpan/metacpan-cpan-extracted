use FindBin;
use lib "$FindBin::Bin/lib";
use Test2::V0 '!meta';
use WWW::WTF::Test;

my $test = WWW::WTF::Test->new();

$test->run_test(sub {
    my ($self) = @_;

    my $http_resource = $self->ua_lwp->get($self->uri_for('/index.html'));
    my @links = $http_resource->get_links({ filter => { title => 'foo' } });

    is(scalar @links, 1);
    is($links[0], '/foo.html');
});

done_testing();
