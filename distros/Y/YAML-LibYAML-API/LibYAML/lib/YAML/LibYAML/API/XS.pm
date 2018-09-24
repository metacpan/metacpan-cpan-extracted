package YAML::LibYAML::API::XS;
use strict;
use warnings;

our $VERSION = '0.000'; # VERSION

use XSLoader;
XSLoader::load('YAML::LibYAML::API::XS', $VERSION);

1;

__END__

=pod

=head1 NAME

YAML::LibYAML::API::XS - Wrapper around the C libyaml library

=cut
