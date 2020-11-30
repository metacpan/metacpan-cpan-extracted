use FindBin;
use lib "$FindBin::Bin/lib";
use Test2::V0 '!meta';
use WWW::WTF::Test;

my $test = WWW::WTF::Test->new();

$test->run_test(sub {
    my ($self) = @_;

    use WWW::WTF::Helpers::Filesystem qw/ remove_directory /;

    my $http_resource = $self->ua_lwp->get($self->uri_for('/pdf_with_images.pdf'));

    my @images = $http_resource->get_images();

    is(scalar @images, 1, 'found an image');

    remove_directory($images[0]) if @images;
});

done_testing();
