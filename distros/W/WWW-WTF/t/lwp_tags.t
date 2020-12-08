use FindBin;
use lib "$FindBin::Bin/lib";
use Test2::V0 '!meta';
use WWW::WTF::Test;

my $test = WWW::WTF::Test->new();

$test->run_test(sub {
    my ($self) = @_;

    my $http_resource = $self->ua_lwp->get($self->uri_for('/tags.html'));

    $http_resource->tag('p')->contains_string('a string');

    my @meta = $http_resource->tag('meta');
    is(scalar @meta, 2);

    $meta[0]->attribute('charset')->contains_string('utf-8');

    my $attributes = $meta[1]->attributes;
    is(scalar @$attributes, 2);

    my @a = $http_resource->tag('a');
    is(scalar @a, 3);

    is($a[0]->uri->as_string, '/index.html');

    my $image = $http_resource->tag('img');
    is($image->src->as_string, '/img2.jpg');

    my @filtered_a = $http_resource->tag('a', {
        filter => {
            attributes => {
                href => 'another',
            },
        },
    });
    is(scalar @filtered_a, 1);
});

done_testing();
