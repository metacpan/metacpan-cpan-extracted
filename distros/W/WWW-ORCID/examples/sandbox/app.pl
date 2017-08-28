#!/usr/bin/perl

use strict;
use warnings;
use WWW::ORCID;
use Dancer;

my $client = WWW::ORCID->new(
    version => '2.0',
    sandbox => 1,
    client_id => $ENV{ORCID_CLIENT_ID},
    client_secret => $ENV{ORCID_CLIENT_SECRET},
);

sub tokens {
    session('tokens') || {};
}

sub add_token {
    my ($token) = @_;
    my $tokens = tokens;
    $tokens->{$token->{orcid}} = $token;
    session(tokens => $tokens);
    $tokens;
}

hook 'before' => sub {
    if (defined(my $orcid = param('orcid'))) {
        tokens->{$orcid} || return redirect('/authorize');
    }
};

get '/' => sub {
    template 'index', {
        tokens => tokens,
        ops    => $client->ops,
    };
};

post '/' => sub {
    my $params = params;
    my $action = $params->{action};
    my $op = $params->{op};
    my $body;
    my $opts = {};
    my $response_body;
    my $success;
    my $error;

    if ($params->{orcid}) {
        $opts->{orcid} = $params->{orcid};
        $opts->{token} ||= tokens->{$opts->{orcid}};
    }
    if ($params->{put_code}) {
        $opts->{put_code} = $params->{put_code};
    }
    if ($params->{body}) {
        $body = from_json($params->{body});
    }

    if ($action eq 'get') {
        if (my $rec = $client->get($op, $opts)) {
            $response_body = to_json($rec);
        }
    }
    elsif ($action eq 'add') {
        if (my $put_code = $client->add($op, $body, $opts)) {
            my $rec = $client->get($op, %$opts, put_code => $put_code);
            $response_body = to_json($rec);
        }
    }
    elsif ($action eq 'update') {
        if (my $rec = $client->update($op, $body, $opts)) {
            $response_body = to_json($rec);
        }
    }
    elsif ($action eq 'delete') {
        if ($client->delete($op, $opts)) {
            $success = "Succesfully deleted";
        }
    }
    if ($client->last_error) {
        $error = to_json($client->last_error);
    }

    template 'index', {
        tokens => tokens,
        ops => $client->ops,
        response_body => $response_body,
        success => $success,
        error => $error,
    };
};

get '/read-public-token' => sub {
    content_type 'application/json';
    to_json($client->read_public_token);
};

get '/read-limited-token' => sub {
    content_type 'application/json';
    to_json($client->read_limited_token);
};

get '/tokens' => sub {
    content_type 'application/json';
    to_json(tokens);
};

get '/authorize' => sub {
    my $params = params;
    redirect $client->authorize_url(
        %$params,
        show_login => 'true',
        scope => '/person/update /activities/update',
        response_type => 'code',
        redirect_uri => 'https://developers.google.com/oauthplayground',
    );
};

get '/authorized' => sub {
    my $code = param('code');
    my $token = $client->access_token(
        grant_type => 'authorization_code',
        code => $code,
    );
    add_token($token);
    content_type 'application/json';
    to_json($token);
};

get '/client' => sub {
    content_type 'application/json';
    to_json($client->client_details(token => $client->read_public_token));
};

get '/search' => sub {
    my $params = params;
    content_type 'application/json';
    to_json($client->search(%$params, token => $client->read_public_token));
};

get '/:orcid/*/?:put_code?' => sub {
    content_type 'application/json';
    my ($path) = splat;
    my $orcid  = param('orcid');
    to_json($client->get($path, token => tokens->{$orcid}, orcid => $orcid));
};

post '/:orcid/?:put_code?' => sub {
    my ($path) = splat;
    my $orcid  = param('orcid');
    my $body = from_json(request->body);
    content_type 'application/json';
    to_json($client->add($path, $body, token => tokens->{$orcid}, orcid => $orcid));
};

put '/:orcid/?:put_code?' => sub {
    my ($path) = splat;
    my $orcid  = param('orcid');
    my $body = from_json(request->body);
    content_type 'application/json';
    to_json($client->update($path, $body, token => tokens->{$orcid}, orcid => $orcid));
};

del '/:orcid/?:put_code?' => sub {
    content_type 'application/json';
    my ($path) = splat;
    my $orcid  = param('orcid');
    to_json($client->delete($path, token => tokens->{$orcid}, orcid => $orcid));
};

dance;
