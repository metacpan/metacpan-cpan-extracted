package Simple::Mock::Class;

use Moo;
extends 'LWP::UserAgent';
with 'Test::Mock::LWP::Distilled';

use HTTP::Response;

sub filename_suffix { 'simple-mock' }

sub distilled_request_from_request {
    my ($self, $request) = @_;

    return $request->uri->path
}

sub distilled_response_from_response {
    my ($self, $response) = @_;

    return $response->decoded_content;
}

sub response_from_distilled_response {
    my ($self, $distilled_response) = @_;

    my $response = HTTP::Response->new;
    $response->content($distilled_response);
    return $response;
}

1;
