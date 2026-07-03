package YAML::XS::LibYAML;
use 5.008001;
use strict;
use warnings;

our $VERSION = 'v0.910.0'; # VERSION

use XSLoader;
XSLoader::load 'YAML::XS::LibYAML';
use base 'Exporter';

our @EXPORT_OK = qw(Load Dump);

1;

=head1 NAME

YAML::XS::LibYAML - An XS Wrapper Module of libyaml

=cut
