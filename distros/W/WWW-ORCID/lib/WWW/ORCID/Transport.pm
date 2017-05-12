package WWW::ORCID::Transport;

use strict;
use warnings;
use namespace::clean;
use URI ();
use Moo::Role;

requires 'get';
requires 'post_form';
requires 'post';

has debug => (is => 'ro');

sub _param_url {
    my ($self, $url, $params) = @_;
    $url = URI->new($url);
    $url->query_form($params);
    $url->as_string;
}

1;
