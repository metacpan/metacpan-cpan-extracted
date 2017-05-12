package WWW::ModulrFinance;

use strict;
use 5.008_005;
our $VERSION = '0.02';

use LWP::UserAgent;
use HTTP::Date qw/time2str/;
use Digest::HMAC_SHA1 qw(hmac_sha1);
use MIME::Base64;
use URI::Escape qw/uri_escape/;
use Carp qw/croak/;
use JSON;

sub new {
    my $class = shift;
    my %params = @_ % 2 ? %{$_[0]} : @_;

    $params{api_key} or croak "api_key is required";
    $params{hmac_secret} or croak "hmac_secret is required";

    $params{base_url} ||= 'https://api-sandbox.modulrfinance.com/api-sandbox/';
    $params{ua} ||= LWP::UserAgent->new(agent => "WWW-ModulrFinance-$VERSION");

    return bless \%params, $class;
}

sub get_accounts {
    (shift)->request('GET', 'accounts', @_);
}

sub get_account {
    my ($self, $id) = @_;
    return $self->request('GET', 'accounts/' . $id);
}

sub update_account {
    my ($self, $id, $data) = @_;
    return $self->request('PUT', 'accounts/' . $id, $data);
}

sub get_customer_accounts {
    my ($self, $cid, $params) = @_;
    return $self->request('GET', 'customers/' . $cid . '/accounts', $params);
}

sub create_customer_account {
    my ($self, $cid, $data) = @_;
    return $self->request('POST', 'customers/' . $cid . '/accounts', $data);
}

sub get_transactions {
    my ($self, $id, $params) = @_;
    return $self->request('GET', 'accounts/' . $id . '/transactions', $params);
}

sub get_payments {
    my ($self, $params) = @_;
    $self->request('GET', 'payments', $params);
}

sub post_payments {
    my ($self, $data) = @_;
    return $self->request('POST', 'payments', $data);
}

sub post_batchpayments {
    my ($self, $data) = @_;
    return $self->request('POST', 'batchpayments', $data);
}

sub get_batchpayment {
    my ($self, $id) = @_;
    return $self->request('GET', 'batchpayments/' . $id);
}

sub request {
    my ($self, $method, $uri, $data) = @_;

    my $url = $self->{base_url} . $uri;
    if ($method eq 'GET' and $data) {
        my $uri = URI->new($url);
        $uri->query_form($data);
        $url = $uri->as_string;
        $data = undef; # don't be in POST content
    }

    my $req = HTTP::Request->new($method => $url => $self->__signature());
    $req->content(encode_json($data)) if $data;

    # print Dumper(\$req); use Data::Dumper;

    my $res = $self->{ua}->request($req);
    if ($res->header('Content-Type') =~ 'json') {
        return decode_json($res->content);
    }

    croak $res->status_line unless $res->is_success;
    return $res->content;
}

sub __signature {
    my ($self) = @_;

    my $date = time2str(time());
    my $nonce = time() . '-' . $$ . '-' . rand(100000);
    my $str = "date: $date\nx-mod-nonce: $nonce";
    my $sig = uri_escape(encode_base64(hmac_sha1($str, $self->{hmac_secret}), ''));

    # Authorization: Signature keyId="57502612d1bb2c0001000025fd53850cd9a94861507a5f7cca236882",algorithm="hmac-sha1",headers="date x-mod-nonce",signature="WBMr%2FYdhysbmiIEkdTrf2hP7SfA%3D"
    return [
        'Date' => $date,
        'x-mod-nonce' => $nonce,
        'Authorization' => qq~Signature keyId="~ . $self->{api_key} . qq~",algorithm="hmac-sha1",headers="date x-mod-nonce",signature="$sig"~,
        "Content-Type" => "application/json;charset=UTF-8",
    ];
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::ModulrFinance - Modulr API

=head1 SYNOPSIS

    use WWW::ModulrFinance;

    my $modulr = WWW::ModulrFinance->new(
        api_key => $ENV{MODULR_APIKEY},
        hmac_secret => $ENV{MODULR_HMAC_SECRET},
    );

    my $res = $modulr->get_accounts;
    say Dumper(\$res);

=head1 DESCRIPTION

WWW::ModulrFinance is for L<https://modulr-technology-ltd.cloud.tyk.io/portal/api-overview/>

=head1 METHODS

=over 4

=item * get_accounts

=item * get_account($id)

=item * update_account($id, $data)

=item * get_customer_accounts($cid)

=item * create_customer_account($cid, $data)

=item * get_transactions($id, { size => 100, ... })

=item * get_payments

=item * post_payments

=item * post_batchpayments

=item * get_batchpayment($id)

=back

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
