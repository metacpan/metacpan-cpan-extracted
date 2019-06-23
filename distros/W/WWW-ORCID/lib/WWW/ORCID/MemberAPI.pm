package WWW::ORCID::MemberAPI;

use strict;
use warnings;

our $VERSION = 0.0402;

use Moo::Role;
use JSON qw(decode_json encode_json);
use namespace::clean;

with 'WWW::ORCID::API';

has read_limited_token => (is => 'lazy');

sub _build_read_limited_token {
    $_[0]->access_token(
        grant_type => 'client_credentials',
        scope      => '/read-limited'
    );
}

sub add {
    my $self = shift;
    $self->_clear_last_error;
    my $path = shift;
    my $data = shift;
    my $opts = ref $_[0] ? $_[0] : {@_};
    my $body = encode_json($data);
    my $url  = _url($self->api_url, $path, $opts);
    my $res  = $self->_t->post($url, $body, _headers($opts, 0, 1));
    if ($res->[0] eq '201') {
        my $loc = $res->[1]->{location};
        my ($put_code) = $loc =~ m|([^/]+)$|;
        return $put_code;
    }
    $self->_set_last_error($res);
    return;
}

sub update {
    my $self = shift;
    $self->_clear_last_error;
    my $path = shift;
    my $data = shift;
    my $opts = ref $_[0] ? $_[0] : {@_};

    # put code needs to be in both path and body
    $data->{'put-code'} ||= $opts->{put_code}   if $opts->{put_code};
    $opts->{put_code}   ||= $data->{'put-code'} if $data->{'put-code'};
    my $body = encode_json($data);
    my $url  = _url($self->api_url, $path, $opts);
    my $res  = $self->_t->put($url, $body, _headers($opts, 1, 1));
    if ($res->[0] eq '200') {
        return decode_json($res->[2]);
    }
    $self->_set_last_error($res);
    return;
}

sub delete {
    my $self = shift;
    $self->_clear_last_error;
    my $path = shift;
    my $opts = ref $_[0] ? $_[0] : {@_};
    my $url  = _url($self->api_url, $path, $opts);
    my $res  = $self->_t->delete($url, undef, _headers($opts, 1));
    if ($res->[0] eq '204') {
        return 1;
    }
    $self->_set_last_error($res);
    return;
}

1;

