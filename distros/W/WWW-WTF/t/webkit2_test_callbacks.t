use FindBin;
use lib "$FindBin::Bin/lib";
use Test2::V0 '!meta';
use Test2::Require::Module 'WWW::WebKit2';
use WWW::WTF::Test;

my $test = WWW::WTF::Test->new(
    ua_webkit2 => WWW::WTF::UserAgent::WebKit2->new(
        callbacks => {
            'resource-load-started' => sub {
                my ($view, $resource, $request) = @_;

                check_request($request->get_uri);
            }
        }
    ),
);

my @seen_uris;

sub check_request {
    my $uri = shift;

    push @seen_uris, $uri;
}

$test->run_test(sub {
    my ($self) = @_;

    my $http_resource = $self->ua_webkit2->get($self->uri_for('/js_external_requests.html'));

    is(@seen_uris, 2, "expected two urls");
    like($seen_uris[0], qr!js_external_requests\.html!);
    like($seen_uris[1], qr!foo\.js$!),
});

done_testing();
