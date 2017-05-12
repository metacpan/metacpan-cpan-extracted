package Test::JSON::RPC::Autodoc::Response;
use strict;
use warnings;
use HTTP::Message::PSGI;
use parent qw/HTTP::Response/;
use Data::Recursive::Encode;
use Encode qw/decode_utf8 encode_utf8/;
use JSON qw//;

sub HTTP::Response::from_json {
    my $self = shift;
    my $content = $self->content();
    return unless $content;
    return JSON::from_json(decode_utf8($content));
}

sub HTTP::Response::pretty_json {
    my $self = shift;
    my $content = $self->content();
    return unless $content;
    my $data = JSON::from_json(decode_utf8($content));
    my $json = JSON::to_json($data, { pretty => 1 });
    return $json;
}

1;
