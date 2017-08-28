package WWW::ORCID::Base;

use strict;
use warnings;

our $VERSION = 0.0401;

use URI      ();
use Log::Any ();
use Moo::Role;
use namespace::clean;

has log => (is => 'lazy',);

sub _build_log {
    Log::Any->get_logger;
}

sub _param_url {
    my ($self, $url, $params) = @_;
    $url = URI->new($url);
    $url->query_form($params);
    $url->as_string;
}

1;

