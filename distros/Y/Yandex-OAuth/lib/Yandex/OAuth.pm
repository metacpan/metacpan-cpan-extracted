=encoding utf-8

=head1 NAME

Yandex::OAuth - module for get access token to Yandex.API

=head1 SYNOPSIS

    use Yandex::OAuth;

    my $oauth = Yandex::OAuth->new(
        client_id     => '76df1cf****************fb31d0289',
        client_secret => 'e3a2855****************4de3c2afc',
    );
    
    # return link for open in browser
    say $oauth->get_code();

    # return JSON with access_token
    say Dumper $oauth->get_token( code => 3557461 );

=head1 DESCRIPTION

Yandex::OAuth is a module for get access token for Yandex.API
See more at https://tech.yandex.ru/oauth/doc/dg/concepts/ya-oauth-intro-docpage/


=cut

package Yandex::OAuth;
use 5.008001;
use utf8;
use Modern::Perl;
use JSON::XS;
use URI::Escape;

use LWP::UserAgent;

use Moo;

our $VERSION = "0.07";

has 'ua' => (
    is => 'ro',
    default => sub {
        my $ua = LWP::UserAgent->new();
        $ua->agent( 'Yandex::OAuth Perl API Client' );
        $ua->timeout( 120 );
        return $ua;
    }
);

has 'auth_url' => (
    is      => 'ro',
    default => 'https://oauth.yandex.ru/authorize',

);

has 'token_url' => (
    is      => 'ro',
    default => 'https://oauth.yandex.ru/token',
);

has 'client_id' => (
    is => 'rw',
    required => 1,
);

has 'client_secret' => (
    is => 'rw',
    required => 1,
);

has 'demo' => (
    is => 'rw'
);

=head1 METHODS

=over

=item B<get_code()>

return a link for open in browser

    $oauth->get_code();

=cut

sub get_code {
    my ( $self, %params ) = @_;

    return $self->auth_url . "?response_type=code&client_id=".$self->client_id . 
        ( ( defined $params{state} ) ? "&state=" . uri_escape( $params{state} ) : '' );
}

=item B<get_token()>

return a json with access_token or error if code has expired

    $oauth->get_token( code => XXXXXX );

=cut

sub get_token {
    my ( $self, %params ) = @_;

    return JSON::XS::decode_json( $self->demo ) if $self->demo;

    my $res = $self->ua->post($self->token_url, {
        code          => $params{code},
        client_id     => $self->client_id,
        client_secret => $self->client_secret,
        grant_type    => 'authorization_code', 
    });

    return JSON::XS::decode_json( $res->content );
}

1;

__END__
=back

=head1 LICENSE

Copyright (C) Andrey Kuzmin.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Andrey Kuzmin E<lt>chipsoid@cpan.orgE<gt>

=cut
