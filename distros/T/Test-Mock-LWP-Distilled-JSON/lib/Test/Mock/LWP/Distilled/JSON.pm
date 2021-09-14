package Test::Mock::LWP::Distilled::JSON;

use Moo::Role;
use LWP::JSON::Tiny;

# Have you updated the version number in the POD below?
our $VERSION = '1.000';
$VERSION = eval $VERSION;

=head1 NAME

Test::Mock::LWP::Distilled::JSON - JSON support for Test::Mock::LWP::Distilled

=head1 VERSION

This is version 1.000.

=head1 SYNOPSIS

 package My::JSON::Test::LWP::UserAgent;
 
 use Moo;
 extends 'LWP::UserAgent::JSON';
 with 'Test::Mock::LWP::Distilled', 'Test::Mock::LWP::Distilled::JSON';
 
 sub filename_suffix { 'my-json-test' }
 
 sub distilled_request_from_request {
     my ($self, $request) = @_;
 
     ...
 }

 # distilled_response_from_response and response_from_distilled_response
 # implemented automatically.

=head1 DESCRIPTION

This is a very simple extension to L<Test::Mock::LWP::Distilled> that
handles the very common case of APIs that return JSON. I<If> you are happy
that only the HTTP code and the JSON content of any website response are
important (you don't need to remember any other headers), then you can just
pull in this code and not worry about having to deal with JSON.

If you occasionally need other information, you may still be able to use this
role but wrap it with method modifiers. Or just steal the code; it's not
complicated.

Note that your base class must be an extension of L<LWP::UserAgent::JSON>
(provided by L<LWP::JSON::Tiny>) for the automatic JSON conversion to work.

=head2 Provided methods

=head3 distilled_response_from_response

Returns a hashref with keys C<code> (the HTTP code) and either
C<json_content> (the result of decoding JSON in the response), or
C<decoded_content> (the raw decoded content) and C<content_type>
(the content type of the response).

=cut

sub distilled_response_from_response {
    my ($self, $response) = @_;

    my %distilled_response = (code => $response->code);
    # LWP::JSON::Tiny returns undef if there's nothing that looks like JSON
    # in the response, so be prepared for this to fail...
    if ($response->can('json_content')) {
        $distilled_response{json_content} = $response->json_content;
    }
    # ...and if so remember the raw contents elsewhere.
    if (!$response->json_content) {
        $distilled_response{content_type} = $response->content_type;
        $distilled_response{decoded_content} = $response->decoded_content;
    }
    return \%distilled_response;
}

=head3 response_from_distilled_response

Converts the recorded mock back.

=cut

sub response_from_distilled_response {
    my ($self, $distilled_response) = @_;

    my $response = HTTP::Response::JSON->new;
    $response->code($distilled_response->{code});
    if ($distilled_response->{json_content}) {
        # HTTP::Request::JSON knows how to construct JSON from a Perl
        # data structure, so reuse its business logic.
        my $request = HTTP::Request::JSON->new;
        $request->json_content($distilled_response->{json_content});
        $response->content_type($request->content_type);
        $response->content($request->content);
    } else {
        $response->content_type($distilled_response->{content_type});
        $response->content($distilled_response->{decoded_content});
    }
    return $response;
}

1;
