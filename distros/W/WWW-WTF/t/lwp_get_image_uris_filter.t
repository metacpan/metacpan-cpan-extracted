use FindBin;
use lib "$FindBin::Bin/lib";
use Test2::V0 '!meta';
use WWW::WTF::Test;

my $test = WWW::WTF::Test->new();

$test->run_test(sub {
    my ($self) = @_;

    my $http_resource = $self->ua_lwp->get($self->uri_for('/image_tags.html'));
    my @image_uris = $http_resource->get_image_uris({
        filter => {
            attributes => {
                alt => 'foo'
            },
        },
    });

    is(scalar @image_uris, 1);
    is($image_uris[0]->src->as_string, '/img2.jpg');
});

done_testing();
