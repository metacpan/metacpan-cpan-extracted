package WebService::Prowl;

use warnings;
use strict;
use 5.008_001; # for utf8::is_utf8()
our $VERSION = '0.08';

use LWP::UserAgent;
use URI::Escape qw(uri_escape_utf8 uri_escape);
use Carp qw(croak);

my $API_BASE_URL = 'https://api.prowlapp.com/publicapi/';

BEGIN {
    @WebService::Prowl::EXPORT = qw( LIBXML );
    if ( eval { require XML::LibXML::Simple } ) {
        *{WebService::Prowl::LIBXML} = sub() {1};
    }
    else {
        require XML::Simple;
        *{WebService::Prowl::LIBXML} = sub() {0};
    }
}

sub new {
    my $class  = shift;
    my %params = @_;
    my $apikey = $params{'apikey'};
    return bless {
        apikey => $params{'apikey'},
        ua    => LWP::UserAgent->new( agent => __PACKAGE__ . '/' . $VERSION ),
        error => '',
        $params{'providerkey'} ? (providerkey => $params{'providerkey'}) : (),
    }, $class;
}

sub ua { $_[0]->{ua} }

sub error { $_[0]->{error} }

sub _build_url {
    my ( $self, $method, %params ) = @_;
    if ($method eq 'verify') {
        croak("apikey is required") unless $self->{apikey};
        my $url = $API_BASE_URL . 'verify?apikey=' . $self->{apikey};
        $url .= '&providerkey=' . $self->{providerkey} if $self->{providerkey};
        return $url;
    }
    elsif ($method eq 'add') {
        croak("apikey is required") unless $self->{apikey};
        my @params = qw/priority application event description url/;
        my $req_params = +{ map { $_ => delete $params{$_} } @params };

        croak("event name is required")       unless $req_params->{event};
        croak("application name is required") unless $req_params->{application};
        croak("description is required")      unless $req_params->{description};

        $req_params->{priority} ||= 0;

        ##XXX: validate url parameter???

        croak("priority must be an integer value in the range [-2, 2]")
            if ( $req_params->{priority} !~ /^-?\d+$/
            || $req_params->{priority} < -2
            || $req_params->{priority} > 2 );

        my %query = (
            apikey => $self->{apikey},
            $self->{providerkey} ? (providerkey => $self->{providerkey}) : (),
            map { $_  => $req_params->{$_} } @params,
        );
        my @out;
        for my $k (keys %query) {
            push @out, sprintf("%s=%s", _uri_escape($k), _uri_escape($query{$k}));
        }
        my $q = join ('&', @out);
        return $API_BASE_URL . 'add?' . $q;
    }
    elsif ($method eq 'retrieve_token') {
        croak("providerkey is required") unless $self->{providerkey};
        return $API_BASE_URL . 'retrieve/token?providerkey=' . $self->{providerkey};
    }
    elsif ($method eq 'retrieve_apikey') {
        croak("providerkey is required") unless $self->{providerkey};
        my $token = $params{'token'};
        croak("token is required") unless $token;
        my $url =  $API_BASE_URL . 'retrieve/apikey?providerkey=' . $self->{providerkey};
        $url .= '&token=' . $token;
        return $url;
    }
}

sub add {
    my ( $self, %params, $cb ) = @_;
    my $url = $self->_build_url('add', %params);
    $self->_send_request($url, $cb);
}

sub verify {
    my ($self) = @_;
    my $url = $self->_build_url('verify');
    $self->_send_request($url);
}

sub retrieve_token {
    my ( $self, %params, $cb ) = @_;
    my $url = $self->_build_url('retrieve_token', %params);
    $self->_send_request($url, $cb);
}

sub retrieve_apikey {
    my ( $self, %params, $cb ) = @_;
    my $url = $self->_build_url('retrieve_apikey', %params);
    $self->_send_request($url, $cb);
}

sub _send_request {
    my ( $self, $url, $cb ) = @_;
    my $res = $self->{ua}->get($url);
    my $data = $self->_xmlin($res->content);
    if ($res->is_error) {
        $self->{error} =
              $data->{error}
            ? $data->{error}{code} . ': ' . $data->{error}{content}
            : '';
        return;
    }
    return $data;
}

sub _xmlin {
    my ( $self, $xml ) = @_;
    if (LIBXML) {
        return XML::LibXML::Simple->new->XMLin( $xml );
    }
    else {
        return XML::Simple->new->XMLin( $xml );
    }
}

sub _uri_escape {
    utf8::is_utf8($_[0]) ? uri_escape_utf8($_[0]) : uri_escape($_[0]);
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WebService::Prowl - a interface to Prowl Public API

=head1 SYNOPSIS

  use WebService::Prowl;

=head1 DESCRIPTION

WebService::Prowl is a interface to Prowl Public API

=head1 SYNOPSIS

This module aims to be a implementation of a interface to the Prowl Public API (as available on http://www.prowlapp.com/api.php)

    use WebService::Prowl;
    my $ws = WebService::Prowl->new(apikey => '40byteshexadecimalstring');
    $ws->verify || die $ws->error();
    $ws->add(application => "Favotter App",
             event       => "new fav",
             description => "your tweet saved as sekimura's favorite",
             url         => "https://github.com/sekimura");

=head1 METHODS

=over 4

=item new(apikey => 40byteshexadecimalstring, providerkey => yetanother40byteshex)

Call new() to create a Prowl Public API client object. You must pass the apikey, which you can generate on "settings" page https://www.prowlapp.com/settings.php

  my $apikey = 'cf09b20df08453f3d5ec113be3b4999820341dd2';
  my $ws = WebService::Prowl->new(apikey => $apikey);

If you have been whitelisted, you may want to use 'providerkey' like this:

  my $apikey      = 'cf09b20df08453f3d5ec113be3b4999820341dd2';
  my $providerkey = '68b329da9893e34099c7d8ad5cb9c94010200121';

  my $ws = WebService::Prowl->new(apikey => $apikey, providerkey => $providerkey);

=item verify()

Sends a verify request to check if apikey is valid or not. return 1 for success.

  $ws->verify();

=item add(application => $app, event => $event, description => $desc, priority => $pri)

Sends a app request to api and return 1 for success.

  application: [256] (required)
      The name of your application

  event: [1024] (required)
      The name of the event

  description: [10000] (required)
      A description for the event

  url: [512] Optional
      *Requires Prowl 1.2* The URL which should be attached to the notification.

  priority: An integer value ranging [-2, 2]
      a priority of the notification: Very Low, Moderate, Normal, High, Emergency
      default is 0 (Normal)

  $ws->add(application => "Favotter App",
           event       => "new fav",
           description => "your tweet saved as sekimura's favorite");

=item retrieve_token()

Get a registration token for use in retrieve/apikey and the associated URL for the user to approve the request.
See example/retrieve to learn how to use retrieve_token() and retrieve_apikey()

success return value looks like this:

    $VAR1 = {
        'success' => {
            'remaining' => '999',
            'resetdate' => '1296803193',
            'code' => '0'
        },
        'retrieve' => {
            'url' => 'https://www.prowlapp.com/retrieve.php?token=fe645f043ce20f7f179c909df062334c14c51a8b',
            'token' => 'fe645f043ce20f7f179c909df062334c14c51a8b'
        }
    };

=item retrieve_apikey(token => $token)

Get an API key from a registration token retrieved in retrieve/token. The user must have approved your request first, or you will get an error response.
See example/retrieve to learn how to use retrieve_token() and retrieve_apikey()

success return value looks like this:

    $VAR1 = {
        'success' => {
            'remaining' => '999',
            'resetdate' => '1296803193',
            'code' => '200'
        },
        'retrieve' => {
            'apikey' => 'd17e9cfffcb0a0c3091beda69cc31b6134c875c8'
        }
    };


=item error()

Returns any error messages as a string.

  $ws->verify() || die $ws->error();

=back

=head1 AUTHOR

Masayoshi Sekimura E<lt>sekimura@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://www.prowlapp.com/>, L<https://itunes.apple.com/us/app/prowl-easy-push-notifications/id320876271?mt=8>

=cut
