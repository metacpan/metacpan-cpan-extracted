package WWW::ORCID::API;

use strict;
use warnings;

our $VERSION = 0.0401;

use Class::Load qw(try_load_class);
use JSON qw(decode_json);
use Sub::Quote qw(quote_sub);
use Carp;
use Moo::Role;
use namespace::clean;

with 'WWW::ORCID::Base';

requires 'ops';
requires '_build_api_url';

has sandbox           => (is => 'ro',);
has client_id         => (is => 'ro', required => 1);
has client_secret     => (is => 'ro', required => 1);
has api_url           => (is => 'lazy',);
has oauth_url         => (is => 'lazy');
has read_public_token => (is => 'lazy');
has transport         => (is => 'lazy',);
has last_error => (
    is       => 'rwp',
    init_arg => undef,
    clearer  => '_clear_last_error',
    trigger  => 1
);
has _t => (is => 'lazy',);

sub _build_oauth_url {
    $_[0]->sandbox
        ? 'https://sandbox.orcid.org/oauth'
        : 'https://orcid.org/oauth';
}

sub _build_read_public_token {
    $_[0]->access_token(
        grant_type => 'client_credentials',
        scope      => '/read-public'
    );
}

sub access_token {
    my $self = shift;
    $self->_clear_last_error;
    my $opts = ref $_[0] ? $_[0] : {@_};
    $opts->{client_id}     = $self->client_id;
    $opts->{client_secret} = $self->client_secret;
    my $url = join('/', $self->oauth_url, 'token');
    my $headers = {'Accept' => 'application/json'};
    my $res = $self->_t->post_form($url, $opts, $headers);

    if ($res->[0] eq '200') {
        return decode_json($res->[2]);
    }
    $self->_set_last_error($res);
    return;
}

sub authorize_url {
    my $self = shift;
    my $opts = ref $_[0] ? $_[0] : {@_};
    $opts->{client_id} = $self->client_id;
    $self->_param_url(join('/', $self->oauth_url, 'authorize'), $opts);
}

sub record_url {
    my ($self, $orcid) = @_;
    $self->sandbox
        ? "http://sandbox.orcid.org/$orcid"
        : "http://orcid.org/$orcid";
}

sub _build_transport {
    'LWP';
}

sub _build__t {
    my ($self)          = @_;
    my $transport       = $self->transport;
    my $transport_class = "WWW::ORCID::Transport::${transport}";
    try_load_class($transport_class)
        or croak("Could not load $transport_class: $!");
    $transport_class->new;
}

sub _trigger_last_error {
    my ($self, $res) = @_;
    $self->log->errorf("%s", $res) if $self->log->is_error;
}

sub _url {
    my ($host, $path, $opts) = @_;
    $path = join('/', @$path) if ref $path;
    $path =~ s|_summary$|/summary|;
    $path =~ s|_|-|g;
    if (defined(my $orcid = $opts->{orcid})) {
        $path = "$orcid/$path";
    }
    if (defined(my $put_code = $opts->{put_code})) {
        $put_code = join(',', @$put_code) if ref $put_code;
        $path = "$path/$put_code";
    }
    join('/', $host, $path);
}

sub _headers {
    my ($opts, $add_accept, $add_content_type) = @_;
    my $token = $opts->{token};
    $token = $token->{access_token} if ref $token;
    my $headers = {'Authorization' => "Bearer $token",};
    if ($add_accept) {
        $headers->{'Accept'} = 'application/vnd.orcid+json';
    }
    if ($add_content_type) {
        $headers->{'Content-Type'} = 'application/vnd.orcid+json';
    }
    $headers;
}

sub _clean {
    my ($opts) = @_;
    delete $opts->{$_} for qw(orcid token put_code);
    $opts;
}

sub client {
    my $self = shift;
    $self->_clear_last_error;
    my $opts = ref $_[0] ? $_[0] : {@_};
    $opts->{token} ||= $self->read_public_token;
    my $url = join('/', $self->api_url, 'client', $self->client_id);
    my $res = $self->_t->get($url, undef, _headers($opts, 1, 0));
    if ($res->[0] eq '200') {
        return decode_json($res->[2]);
    }
    $self->_set_last_error($res);
    return;
}

sub search {
    shift->get('search', @_);
}

sub get {
    my $self = shift;
    $self->_clear_last_error;
    my $path = shift;
    my $opts = ref $_[0] ? $_[0] : {@_};
    $opts->{token} ||= $self->read_public_token;
    my $url = _url($self->api_url, $path, $opts);
    my $headers = _headers($opts, 1, 0);
    my $res = $self->_t->get($url, _clean($opts), $headers);

    if ($res->[0] eq '200') {
        return decode_json($res->[2]);
    }
    $self->_set_last_error($res);
    return;
}

sub install_helper_methods {
    my $class = $_[0];
    my $ops   = $class->ops;
    for my $op (sort keys %$ops) {
        my $spec = $ops->{$op};
        my $sym  = $op;
        $sym =~ s|[-/]|_|g;

        if ($spec->{get} || $spec->{get_pc} || $spec->{get_pc_bulk}) {
            quote_sub("${class}::${sym}", qq|shift->get('${op}', \@_)|);
        }

        if ($spec->{add}) {
            quote_sub("${class}::add_${sym}", qq|shift->add('${op}', \@_)|);
        }

        if ($spec->{update}) {
            quote_sub("${class}::update_${sym}",
                qq|shift->update('${op}', \@_)|);
        }

        if ($spec->{delete}) {
            quote_sub("${class}::delete_${sym}",
                qq|shift->delete('${op}', \@_)|);
        }
    }

    1;
}

1;
