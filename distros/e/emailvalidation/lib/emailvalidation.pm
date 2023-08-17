package Emailvalidation;

use strict;
use warnings;

use LWP::UserAgent;
use JSON;

our $VERSION = '1.0';
our $BASE_URL = 'https://api.emailvalidation.io';

sub new {
    my ($class, %args) = @_;

    my $self = {};

    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->ssl_opts('verify_hostname' => 0);
    $self->{ua}->default_headers(HTTP::Headers->new(
        Accept => 'application/json',
        apikey =>  $args{apikey}
    ));

    $self->{ua}->agent('Emailvalidation/Perl/$VERSION');


    return bless $self, $class;
}

sub info {

    my ($self, $email) = @_;

    my $url = $BASE_URL . '/v1/info?email=' . $email;
    my $response = $self->{ua}->get($url);


    if ($response->is_success) {

        my $data = $response->decoded_content;
        return $data;
    }
    else {
        die $response->decoded_content;
    }
}

1;
