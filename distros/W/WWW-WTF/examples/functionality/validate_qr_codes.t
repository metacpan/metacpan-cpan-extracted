use common::sense;
use WWW::WTF::Testcase;

my $test = WWW::WTF::Testcase->new();

$test->run_test(sub {
    my ($self) = @_;

    use WWW::WTF::Helpers::QRCode qw/ get_uri_from_qr_code_data_uri /;

    my $iterator = $self->ua_lwp->recurse($self->uri_for('/sitemap.xml'));

    while (my $http_resource = $iterator->next) {
        my $uri = $http_resource->request_uri;

        $self->run_subtest($uri, sub {
            my @qr_code_uris = $http_resource->get_image_uris({
                filter => {
                    attributes => {
                        alt => 'QR\-Code',
                    },
                },
            });

            foreach my $qr_code_data (@qr_code_uris) {
                my $qr_code_uri = get_uri_from_qr_code_data_uri($qr_code_data->src);
                my $response = $self->ua_lwp->get($qr_code_uri);

                $response->successful
                    ? $self->report->pass("URI from QR code is reachable: $qr_code_uri")
                    : $self->report->fail("URI from QR code is unreachable: $qr_code_uri")
                ;
            }
        });
    }
});
