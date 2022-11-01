use strict;
use warnings;

use v5.010;

package WebService::SmartRow;
$WebService::SmartRow::VERSION = '0.007';
# ABSTRACT: Connect and get data from SmartRow API

use HTTP::Tiny;
use JSON::MaybeXS;

use Moo;
use namespace::clean;

has username => ( is => 'ro', required => 0 );
has password => ( is => 'ro', required => 0 );

has http => (
    is      => 'ro',
    default => sub {
        return HTTP::Tiny->new();
    },
);

# https://smartrow.fit/api/challenge
sub get_challenges {
    my $self = shift;

    my ( $user, $pass ) = $self->_credentials_via_env;

    my $response = $self->http->request( 'GET',
              'https://'
            . $user . ':'
            . $pass . '@'
            . 'smartrow.fit/api/challenge' );

    if ( !$response->{success} ) {
        return 'Response error';
    }

    my $json = decode_json $response->{content};

    return $json;
}

# https://smartrow.fit/api/account
sub get_profile {
    my $self = shift;

    my ( $user, $pass ) = $self->_credentials_via_env;

    my $response = $self->http->request( 'GET',
        'https://' . $user . ':' . $pass . '@' . 'smartrow.fit/api/account' );

    if ( !$response->{success} ) {
        return 'Response error';
    }

    my $json = decode_json $response->{content};

    return $json->[0];
}

# https://smartrow.fit/api/public-game
sub get_workouts {
    my $self = shift;

    my ( $user, $pass ) = $self->_credentials_via_env;

    my $response = $self->http->request( 'GET',
              'https://'
            . $user . ':'
            . $pass . '@'
            . 'smartrow.fit/api/public-game' );

    if ( !$response->{success} ) {
        return 'Response error';
    }

    my $json = decode_json $response->{content};

    return $json;
}

sub get_leaderboard {
    my ( $self, %args ) = @_;

    $args{distance} //= 2000;

    my $params_string = '';
    for my $key ( keys %args ) {
        $params_string .= sprintf( "%s=%s&", $key, $args{$key} );
    }

    my ( $user, $pass ) = $self->_credentials_via_env;

    my $response = $self->http->request( 'GET',
              'https://'
            . $user . ':'
            . $pass . '@'
            . 'smartrow.fit/api/leaderboard?'
            . $params_string );

    if ( !$response->{success} ) {
        return 'Response error';
    }

    my $json = decode_json $response->{content};

    return $json->[0];
}

sub _credentials_via_env {
    my $self = shift;

    my $user = $self->username || $ENV{SMARTROW_USERNAME};
    # Escape the "@" as perl basic auth requirement
    $user =~ s/@/%40/g;

    my $pass = $self->password || $ENV{SMARTROW_PASSWORD};

    return ( $user, $pass ),;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::SmartRow - Connect and get data from SmartRow API

=head1 VERSION

version 0.007

=head1 SYNOPSIS

This module is a basic wrapper to allow Perl apps to access data from https://smartrow.fit

 my $smartrow = WebService::SmartRow->new(
  username => 'foo',
  password => 'bar',
 );

 my $profile  = $smartrow->get_profile;
 my $workouts = $smartrow->get_workouts;

Credentials can be passed via environment variables

* SMARTROW_USERNAME
* SMARTROW_PASSWORD

If passing credentials via ENV you can simply use WebService::SmartRow->new;

=head1 ATTRIBUTES

=head2 http

http is a HTTP::Tiny object by default, you can provide your own on construction.

This might be helpful if, for example, you wanted to change the user agent.

=head2 username

get/set the username for the API

Note that we parse the username in get_ methods to escape the "@" char.

You can also set the SMARTROW_USERNAME environment variable.

=head2 password

get/set the password for the API

You can also set the SMARTROW_PASSWORD environment variable.

=head1 METHODS

=head2 get_profile

This method obtains your profile information

=head2 get_workouts

This method returns all the workouts you have done via SmartRow

=head2 get_leaderboard

This method returns the data presented in the leaderboard (AKA Rankings page).

Unlike the first two methods, get_leaderboard can accept parameters to limit the data.

e.g.
    my $leaderboard = $srv->get_leaderboard(
         distance => 5000,  # If not provided will default to 2000
         year     => 2022,
         country  => 188,
         age      => 'c',
         gender   => 'f',   # m or f (male or female)
         weight   => 'l',   # l or h (light or heavy)
     );

More details on values able to be used to follow.

=head2 get_challenges

This method returns an array of challenges, there are no parameters.

=head1 AUTHOR

Lance Wicks <lw@judocoach.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Lance Wicks.

This is free software, licensed under:

  The MIT (X11) License

=cut
