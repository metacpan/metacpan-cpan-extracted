package WWW::Yotpo;

use strict;
use 5.008_005;
our $VERSION = '0.03';

use Carp;
use LWP::UserAgent;
use JSON;
use HTTP::Request;
use vars qw/$errstr/;

sub errstr { $errstr }

sub new {
    my $class = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $args{client_id} or croak 'client_id is required.';
    $args{client_secret}  or croak 'client_secret is required.';

    $args{ua} ||= LWP::UserAgent->new;

    return bless \%args, $class;
}

sub oauth_token {
    my $self = shift;
    my %params = @_ % 2 ? %{$_[0]} : @_;
    $self->request('oauth/token', 'POST', {
        "client_id" => $self->{client_id},
        "client_secret" => $self->{client_secret},
        "grant_type" => "client_credentials"
    });
}

sub mass_create {
    my $self = shift;
    my %params = @_ % 2 ? %{$_[0]} : @_;
    $self->request('apps/' . $self->{client_id} . '/purchases/mass_create', 'POST', {
        Content => encode_json(\%params),
        utoken => $params{utoken}
    });
}

sub purchases {
    my $self = shift;
    my %params = @_ % 2 ? %{$_[0]} : @_;
    $self->request('apps/' . $self->{client_id} . '/purchases', 'GET', \%params);
}

sub request {
    my ($self, $url, $method, $params) = @_;

    $url = 'https://api.yotpo.com/' . $url;

    $params ||= {};
    my $content = delete $params->{Content};

    my $uri = URI->new($url);
    $uri->query_form($params) if keys %$params;

    my $req = HTTP::Request->new($method, $uri);
    if ($content) {
        $req->content($content);
        $req->content_type('application/json');
    }
    my $res = $self->{ua}->request($req);
    # print Dumper(\$res); use Data::Dumper;
    if (not $res->header('Content-Type') =~ /json/) {
        $errstr = $res->status_line;
        return;
    }

    return decode_json($res->decoded_content);
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::Yotpo - API for Yotpo

=head1 SYNOPSIS

    use WWW::Yotpo;

    my $yotpo = WWW::Yotpo->new(
        client_id => $ENV{YOTPO_CLIENT_ID}, # from https://my.yotpo.com/settings
        client_secret => $ENV{YOTPO_CLIENT_SECRET},
    );

    my $token = $yotpo->oauth_token();
    my $access_token = $token->{access_token}; # save it somewhere

    my $res = $yotpo->mass_create(
        utoken => $access_token,
        platform => 'general',
        orders => [
            {
                "email" => "client\@example.com",
                "customer_name" => "bob",
                "order_id" => "1121",
                "order_date" => "2013-05-01",
                "currency_iso" => "USD",
                ....

    my $res = $yotpo->purchases(
        utoken => $access_token,
    );

=head1 DESCRIPTION

WWW::Yotpo is for L<http://docs.yotpoapi.apiary.io/>

=head1 AUTHOR

Fayland Lam E<lt>fayland@binary.comE<gt>

=head1 COPYRIGHT

Copyright 2015- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
