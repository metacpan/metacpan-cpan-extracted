package WebService::DeathByCaptcha;

use strict;
use 5.008_005;
our $VERSION = '0.02';

use Carp 'croak';
use LWP::UserAgent;
use JSON;
use Try::Tiny;

use vars qw/$errstr/;
sub errstr { $errstr }

sub new {
    my $class = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    $args{username} or croak "username is required.\n";
    $args{password} or croak "password is required.\n";
    $args{ua} ||= LWP::UserAgent->new;
    $args{ua}->default_header('Accept' => 'application/json');
    $args{url} ||= 'http://api.dbcapi.me/api/captcha';
    $args{sleep} ||= 3;

    return bless \%args, $class;
}

sub recaptcha {
    my $self = shift;
    my %params = @_ % 2 ? %{$_[0]} : @_;

    $params{googlekey} or croak "googlekey is required.\n";
    $params{pageurl}   or croak "pageurl is required.\n";

    return $self->request(
        __method => 'POST',
        type => 4,
        token_params => encode_json(\%params)
    );
}

sub get {
    my ($self, $id) = @_;

    return $self->request(
        url => "http://api.dbcapi.me/api/captcha/$id"
    );
}

sub request {
    my ($self, %params) = @_;

    $params{username} ||= $self->{username};
    $params{password} ||= $self->{password};
    my $url = delete $params{url} || $self->{url};

    my $res;
    my $method = delete $params{__method} || 'GET';
    if ($method eq 'POST') {
        $res = $self->{ua}->post($url, \%params);
    } else {
        my $uri = URI->new($url);
        $uri->query_form(%params);
        $res = $self->{ua}->get($uri->as_string);
    }

    # print Dumper(\$res); use Data::Dumper;

    my $res = try { decode_json($res->content) };
    return $res if $res;

    $errstr = "Failed to $method $url: " . $res->status_line;
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::DeathByCaptcha - DeathByCaptcha Recaptcha API

=head1 SYNOPSIS

    use WebService::DeathByCaptcha;

    my $dbc = WebService::DeathByCaptcha->new(
        username => 'dbc_user',
        password => 'dbc_pass',
    );

    my $dbc_res = $dbc->recaptcha({
        googlekey => '6Le-wvkSAAAAAPBMRTvw0Q4Muexq9bi0DJwx_mJ-',
        pageurl => 'https://www.google.com/recaptcha/api2/demo',
        # proxy => "http://user:password@127.0.0.1:1234",
        # proxytype => 'HTTP',
    }) or die $dbc->errstr;

    die $dbc_res->{error} if $dbc_res->{error};
    my $captcha_id = $dbc_res->{captcha};

    sleep 60;
    my $recaptcha_res;
    while (1) {
        $dbc_res = $dbc->get($captcha_id);
        die $dbc_res->{error} if $dbc_res->{error};

        warn Dumper(\$dbc_res);
        if ($dbc_res->{status} eq '0' and $dbc_res->{text}) {
            $recaptcha_res = $dbc_res->{text};
            last;
        } elsif ($dbc_res->{status} eq '0') {
            sleep 5; # another sleep
        } else {
            die; # should never happen
        }
    }

    # $res = $ua->post('https://www.google.com/recaptcha/api2/demo', Content => [
    #     'g-recaptcha-response' => $recaptcha_res,
    # ]);

=head1 DESCRIPTION

WebService::DeathByCaptcha is for L<http://www.deathbycaptcha.com/user/api/newtokenrecaptcha>

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
