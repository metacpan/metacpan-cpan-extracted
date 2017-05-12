package WWW::Foursquare::Response;

use strict;
use warnings;

use JSON;

our %ERROR_TYPE = (
    invalid_auth        => 'OAuth token was not provided or was invalid',
    param_error         => 'A required parameter was missing or a parameter was malformed. This is also used if the resource ID in the path is incorrect',
    endpoint_error      => 'The requested path does not exist',
    not_authorized      => 'Although authentication succeeded, the acting user is not allowed to see this information due to privacy restrictions',
    rate_limit_exceeded => 'Rate limit for this hour exceeded',
    deprecated          => 'Something about this request is using deprecated functionality, or the response format may be about to change',
    server_error        => 'erver is currently experiencing issues. Check status.foursquare.com for updates',
    other               => 'Some other type of error occurred',
    unknown             => 'Unknown error',
);

sub new {
    my ($class, $params) = @_;

    my $self = {};
    bless $self, $class;
    return $self;
}

sub process {
    my ($self, $res) = @_;

    my $data = decode_json($res->content());
    my $code = $res->code();

    # response is OK
    return $data->{response} if $code == 200;

    # need error handling
    my $error_type = $data->{meta}->{errorType}   || 'unkwown';
    my $error_desc = $ERROR_TYPE{$error_type} || $data->{meta}->{errorDetail} || 'no details';
    my $error_text = sprintf "%s %s", $error_type, $error_desc;

    # raise exception
    die $error_text;
}


1;
