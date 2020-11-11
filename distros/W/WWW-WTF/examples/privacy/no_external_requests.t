use common::sense;
use Test2::V0 '!meta';
use WWW::WTF::Testcase;

my $test = WWW::WTF::Testcase->new(
    ua_webkit2 => WWW::WTF::UserAgent::WebKit2->new(
        callbacks => {
            'resource-load-started' => sub {
                my ($view, $resource, $request) = @_;

                check_request($request->get_uri);
            }
        }
    ),
);

my %seen_uris;

sub check_request {
    my $uri = shift;

    my $base_uri = $test->base_uri->as_string;

    return if exists $seen_uris{$uri};

    return if $uri =~ m!^data:!;

    $uri =~ m!$base_uri!
        ? pass("URI request isn't external: $uri")
        : fail("URI request to external detected: $uri");

    $seen_uris{$uri} = 1;
}

$test->run_test(sub {
    my ($self) = @_;

    my $iterator = $self->ua_webkit2->recurse($self->uri_for('/sitemap.xml'));

    while (my $http_resource = $iterator->next) {

        # checked by callback
    }

    done_testing();
});
