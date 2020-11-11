use common::sense;
use Test2::V0 '!meta';
use WWW::WTF::Testcase;

my $test = WWW::WTF::Testcase->new();

$test->run_test(sub {
    my ($self) = @_;

    use WWW::WTF::Helpers::QRCode qw/ get_uri_from_qr_code_data_uri /;

    my $iterator = $self->ua_lwp->recurse($self->uri_for('/sitemap.xml'));

    while (my $http_resource = $iterator->next) {
        my @qr_code_uris = $http_resource->get_image_uris({
            filter => {
                alt => 'QR\-Code',
            }
        });

        foreach my $qr_code_data (@qr_code_uris) {
            my $uri = get_uri_from_qr_code_data_uri($qr_code_data);
            my $response = $self->ua_lwp->get($uri);

            $response->successful
                ? pass("URI in QR code is reachable: $uri")
                : fail("Unreachable URI in QR Code found: $uri")
            ;
        }
    }

    done_testing();
});
