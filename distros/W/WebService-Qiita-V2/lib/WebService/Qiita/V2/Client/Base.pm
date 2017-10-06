package WebService::Qiita::V2::Client::Base;
use strict;
use warnings;

use JSON;
use LWP::UserAgent;
use HTTP::Request;
use URI;

use constant {
    API_URL => 'qiita.com/api/',
    API_VER => 'v2',
};

sub new {
    my ($class, $args) = @_;

    $args ||= {};
    $args = {%$args, (
        ua => undef,
        error => undef,
    )};
    my $self = bless $args, $class;
    $self;
}

sub ua {
    my $self = shift;
    return $self->{ua} if defined $self->{ua};
    my $options = {
        ssl_opts => { verify_hostname => 0 },
    };
    $self->{ua} = LWP::UserAgent->new(%$options);
}

sub get {
    my ($self, $func, $params, $args) = @_;

    my $url = 'https://' . $self->_team($args) . API_URL . API_VER . "/$func";
    my $uri = URI->new($url);
    if ($params) {
        $uri->query_form(%$params);
    }

    my $req = HTTP::Request->new("GET", $uri->as_string);
    if (defined $args->{headers}) {
        for (keys %{$args->{headers}}) {
            $req->header($_ => $args->{headers}->{$_});
        }
    }
    $req->content_type('application/json');

    my $res = $self->ua->request($req);

    if ($res->code == 200) {
        my $result = ($res->content) ? JSON::decode_json($res->content) : "";
        return $result;
    }

    $self->_set_error($res, $url, "GET");
    return -1;
}

sub post {
    my ($self, $func, $params, $args) = @_;

    my $url = 'https://' . $self->_team($args) . API_URL . API_VER . "/$func";
    my $uri = URI->new($url);

    my $req = HTTP::Request->new("POST", $uri);
    if (defined $args->{headers}) {
        for (keys %{$args->{headers}}) {
            $req->header($_ => $args->{headers}->{$_});
        }
    }
    $req->content_type('application/json');
    $req->content(JSON::encode_json $params);

    my $res = $self->ua->request($req);

    if ($res->code == 201) {
        my $result = ($res->content) ? JSON::decode_json($res->content) : "";
        return $result;
    }

    $self->_set_error($res, $url, "POST");
    return -1;
}

sub put {
    my ($self, $func, $params, $args) = @_;

    my $url = 'https://' . $self->_team($args) . API_URL . API_VER . "/$func";
    my $uri = URI->new($url);

    my $req = HTTP::Request->new("PUT", $uri);
    if (defined $args->{headers}) {
        for (keys %{$args->{headers}}) {
            $req->header($_ => $args->{headers}->{$_});
        }
    }
    $req->content_type('application/json');
    $req->content(JSON::encode_json $params) if defined $params;

    my $res = $self->ua->request($req);

    return 1 if $res->code == 204;

    $self->_set_error($res, $url, "PUT");
    return -1;
}

sub patch {
    my ($self, $func, $params, $args) = @_;

    my $url = 'https://' . $self->_team($args) . API_URL . API_VER . "/$func";
    my $uri = URI->new($url);

    my $req = HTTP::Request->new("PATCH", $uri);
    if (defined $args->{headers}) {
        for (keys %{$args->{headers}}) {
            $req->header($_ => $args->{headers}->{$_});
        }
    }
    $req->content_type('application/json');
    $req->content(JSON::encode_json $params);

    my $res = $self->ua->request($req);

    if ($res->code == 200) {
        my $result = ($res->content) ? JSON::decode_json($res->content) : "";
        return $result;
    }

    $self->_set_error($res, $url, "PATCH");
    return -1;
}

sub delete {
    my ($self, $func, $params, $args) = @_;

    my $url = 'https://' . $self->_team($args) . API_URL . API_VER . "/$func";
    my $uri = URI->new($url);
    if ($params) {
        $uri->query_form(%$params);
    }

    my $req = HTTP::Request->new("DELETE", $uri->as_string);
    if (defined $args->{headers}) {
        for (keys %{$args->{headers}}) {
            $req->header($_ => $args->{headers}->{$_});
        }
    }
    $req->content_type('application/json');

    my $res = $self->ua->request($req);

    return 1 if $res->code == 204;

    $self->_set_error($res, $url, "DELETE");
    return -1;
}

sub get_response_code {
    my ($self, $func, $params, $args) = @_;

    my $url = 'https://' . $self->_team($args) . API_URL . API_VER . "/$func";
    my $uri = URI->new($url);
    if ($params) {
        $uri->query_form(%$params);
    }

    my $req = HTTP::Request->new("GET", $uri->as_string);
    if (defined $args->{headers}) {
        for (keys %{$args->{headers}}) {
            $req->header($_ => $args->{headers}->{$_});
        }
    }
    $req->content_type('application/json');

    my $res = $self->ua->request($req);
    if ($res->code >= 300) {
        $self->_set_error($res, $url, "GET");
    }
    return $res->code;
}

sub _set_error {
    my ($self, $res, $url, $method) = @_;

    my $content = ($res->content) ? JSON::decode_json($res->content) : "";

    $self->{error} = {
        method => $method,
        url => $url,
        code => $res->code,
        content => $content,
    };
}

sub _team {
    my ($self, $args) = @_;
    return $args->{team} . "." if (defined $args->{team});
    return "";
}

1;
