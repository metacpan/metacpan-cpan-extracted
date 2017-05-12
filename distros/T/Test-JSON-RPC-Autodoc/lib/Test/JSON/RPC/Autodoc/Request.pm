package Test::JSON::RPC::Autodoc::Request;
use strict;
use warnings;
use parent qw/HTTP::Request/;
use Clone qw/clone/;
use JSON qw/to_json/;
use Test::Builder;
use Try::Tiny;
use Test::JSON::RPC::Autodoc::Response;
use Test::JSON::RPC::Autodoc::Validator;
use Plack::Test::MockHTTP;

sub new {
    my ($class, %opt) = @_;
    my $self = $class->SUPER::new();
    $self->uri($opt{path} || '/');
    $self->{method} = 'POST';
    $self->{app} = $opt{app};
    $self->{id} = $opt{id} || 1;
    $self->{label} = $opt{label} || undef;
    return $self;
}

sub json_rpc_method {
    my ($self, $name) = @_;
    return $self->{json_rpc_method} unless $name;
    $self->{json_rpc_method} = $name;
    return $name;
}

sub main_content {
    my ($self, $content) = @_;
    return $self->{main_content} unless $content;
    $self->{main_content} = $content;
    return $content;
}

sub params {
    my ($self, %params) = @_;
    $self->{rule} = clone \%params;
    for my $p (%params) {
        next unless ref $p eq 'HASH';
        for my $key (keys %$p) {
            if ( $key eq 'required' ) {
                $p->{optional} = !$p->{required};
                delete $p->{$key};
            }
        }
    }
    my $validator = Data::Validator->new(%params)->with('NoThrow');
    $self->{validator} = $validator;
    return $validator;
}

sub validator {
    my $self = shift;
    return $self->{validator} if $self->{validator};
    return Data::Validator->new->with('NoThrow');
}

sub post_ok {
    my ($self, $method, $params, $headers) = @_;
    $params ||= {};
    my $args = $self->validator->validate(%$params);
    my $ok = 1;
    $ok = 0 if $self->validator->has_errors;
    $self->validator->clear_errors();

    my $json = $self->_make_request($method, $params, $headers);

    my $mock = Plack::Test::MockHTTP->new($self->{app});
    my $res = $mock->request($self);
    $ok = 0 if $res->code != 200;
    my $Test = Test::Builder->new();
    $Test->ok($ok);

    $self->{response} = $res;
    $self->{main_content} = $json;
    $self->{json_rpc_method} = $method;
    return $res;
}

sub post_only {
    my ($self, $method, $params, $headers) = @_;
    $self->_make_request($method, $params, $headers);
    my $mock = Plack::Test::MockHTTP->new($self->{app});
    my $res = $mock->request($self);
    return $res;
}

sub post_not_ok {
    my ($self, $method, $params, $headers) = @_;
    $params ||= {};
    my $args = $self->validator->validate(%$params);

    my $ok = 1 if $self->validator->has_errors;
    $self->validator->clear_errors();

    $self->_make_request($method, $params, $headers);

    my $mock = Plack::Test::MockHTTP->new($self->{app});
    my $res = $mock->request($self);
    $ok = 1 if $res->code == 200;
    my $Test = Test::Builder->new();
    $Test->ok($ok);
}

sub _make_request {
    my ($self, $method, $params, $headers) = @_;
    my $json = to_json(
        {
            jsonrpc => '2.0',
            id => $self->{id},
            method  => $method,
            params  => $params,
        }, { pretty => 1, utf8 => 1 }
    );
    $self->header('Content-Type' => 'application/json');
    $self->header('Content-Length' => length $json);
    if($headers && ref $headers eq 'ARRAY') {
        for my $header (@$headers) {
            $self->header(@$header);
        }
    }
    $self->content($json);
    return $json;
}

sub method { shift->{method} }
sub rule { shift->{rule} }
sub label { shift->{label} }

sub response {
    my $self = shift;
    return $self->{response} if $self->{response};
    return;
}

1;
