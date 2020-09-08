package YAML::LibYAML::API::XS;
use strict;
use warnings;

our $VERSION = '0.012'; # VERSION

use XSLoader;
XSLoader::load('YAML::LibYAML::API::XS', $VERSION);

sub parse_events {
    parse_string_events(@_);
}

1;

__END__

=pod

=head1 NAME

YAML::LibYAML::API::XS - Wrapper around the C libyaml library

=cut
