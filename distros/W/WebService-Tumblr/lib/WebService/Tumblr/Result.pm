package WebService::Tumblr::Result;

use strict;
use warnings;

use Any::Moose;
use Try::Tiny;

has dispatch => qw/ is ro required 1 isa WebService::Tumblr::Dispatch /, handles => [qw/ tumblr /];
has request => qw/ is ro required 1 isa HTTP::Request /;
has response => qw/ is ro required 1 isa HTTP::Response /, handles => [qw/ is_success /];

sub _error {
    my $self = shift;
    my $error = shift;
    $error .= ": " . $self->response->status_line;
    return $error;
}

sub _content {
    my $self = shift;
    return $self->response->decoded_content;
}

sub content {
    my $self = shift;
    my $response = $self->response;
    die $self->_error( "*** Invalid response" ) unless $response->is_success;
    return $response->decoded_content;
}

has value => qw/ is ro lazy_build 1 /;
sub _build_value {
    my $self = shift;
    my $value = $self->content;
    try {
        if ( $self->response->content_type =~ m/json/ ) {
            $value =~ s/^var tumblr_api_read = //;
            $value =~ s/;$//;
            $value = WebService::Tumblr::json->decode( $value );
        }
    }
    catch {
        die $self->_error( "*** Unable to parse: $_[0]" );
    };
    return $value;
}

1;
