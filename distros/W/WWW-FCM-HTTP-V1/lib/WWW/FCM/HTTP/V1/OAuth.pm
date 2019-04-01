package WWW::FCM::HTTP::V1::OAuth;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Class::Accessor::Lite (
    new => 0,
    ro => [qw/ua jwt_config scopes grant_type timeout expires_in/],
    rw => [qw/token_url cache/],
);

use JSON qw(encode_json decode_json);
use JSON::WebToken;
use Furl;
use HTTP::Status qw(:constants);
use Carp qw(carp croak);

our $DEFAULT_TOKEN_URL  = "https://accounts.google.com/o/oauth2/token";
our $DEFAULT_GRANT_TYPE = "urn:ietf:params:oauth:grant-type:jwt-bearer";
our $DEFAULT_TIMEOUT    = 5;
our $DEFAULT_EXPIRES_IN = 3600;

sub new {
    my ($class, %args) = @_;
    $args{grant_type} ||= $DEFAULT_GRANT_TYPE;
    $args{timeout}    ||= $DEFAULT_TIMEOUT;
    $args{scopes}     ||= [];
    $args{jwt_config} ||= _jwt_config_from_json($args{api_key_json}, $args{scopes});
    $args{token_url}  ||= $args{jwt_config}->{token_url};
    $args{ua}         ||= Furl->new(timeout => $args{timeout});
    $args{cache}      ||= undef; # if you will cache the oAuth token, create get/set/delete method
    $args{expires_in} ||= $DEFAULT_EXPIRES_IN; # for cache

    bless \%args, $class;
}

sub request {
    my ($self, %args) = @_;

    my $token = $self->get_token(force_refresh => $args{retry});

    my $res = $self->ua->request(
        method => $args{method},
        url => $args{uri},
        headers => [
            'Content-Type' => $args{content_type} || 'application/json; UTF-8',
            'Authorization' => sprintf("Bearer %s", $token->{access_token}),
        ],
        content => $args{content} || (),
    );

    if ($res->code == HTTP_UNAUTHORIZED && !$args{retry}) {
        $args{retry} = 1;
        return $self->request(%args);
    }

    return $res;
}

sub _jwt_config_from_json {
    my ($json, $scopes) = @_;
    my $secret = decode_json($json);

    return +{
        client_email   => $secret->{client_email},
        private_key    => $secret->{private_key},
        private_key_id => $secret->{private_key_id},
        scopes         => $scopes,
        token_url      => $secret->{token_url} || $DEFAULT_TOKEN_URL,
    };
}

sub get_token {
    my ($self, %args) = @_;

    my $cache_key = $self->jwt_config->{private_key_id};
    if ($self->cache) {
        if ($args{force_refresh}) {
            $self->cache->delete($cache_key);
        } else {
            my $token_cache = $self->cache->get($cache_key);
            return $token_cache if $token_cache;
        }
    }

    my $claims = $self->_construct_claims($self->jwt_config);
    my $jwt = JSON::WebToken->encode($claims, $self->jwt_config->{private_key}, 'RS256');
    my $res = $self->ua->post(
        $self->token_url,
        ['Content-Type' => 'application/x-www-form-urlencoded'],
        ['grant_type' => $self->grant_type, assertion => $jwt],
    );
    unless ($res->is_success) {
        croak sprintf('Failed to get access token. %s [req] %s [res] %s', $res->status_line, $res->request->request_line, $res->content)
    }

    my $res_content; 
    eval {
        $res_content = decode_json($res->content);
    };
    if ( my $e = $@ ) {
        croak sprintf('decode_json error. %s', $e),
    }

    if ($self->cache) {
        eval {
            $self->cache->set($cache_key, $res_content, $self->expires_in) if $res_content;
        };
        if ( my $e = $@ ) {
            carp sprintf('Failed to set cache. %s %s', $e),
        }
    }

    return $res_content;
}

sub _construct_claims {
    my ($self, $config) = @_;
    my $result = +{};
    my $now = time;
    $result->{iss}   = $config->{client_email};
    $result->{scope} = join(' ', @{$config->{scopes}});
    $result->{aud}   = $config->{token_url};
    $result->{iat}   = $now;
    $result->{exp}   = $now + $self->expires_in;
    $result->{sub}   = $config->{subject} if defined $config->{subject};
    # prn is the old name of sub. Keep setting it
    # to be compatible with legacy OAuth 2.0 providers.
    $result->{prn}   = $config->{subject} if defined $config->{subject};

    return $result;
}

1;
