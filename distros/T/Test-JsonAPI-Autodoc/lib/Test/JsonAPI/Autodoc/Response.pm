package Test::JsonAPI::Autodoc::Response;
use strict;
use warnings;
use utf8;
use JSON;

sub new {
    my ($class) = @_;

    bless {
    }, $class;
}

sub parse {
    my ($self, $res) = @_;

    my $body         = $res->content;
    my $content_type = $res->content_type;
    if ($content_type =~ m!^application/json!) {
        $body = to_json(from_json($res->decoded_content, { utf8 => 1 }), { pretty => 1, canonical => 1 });
    }

    return {
        body         => $body,
        content_type => $content_type,
    };
}

1;
