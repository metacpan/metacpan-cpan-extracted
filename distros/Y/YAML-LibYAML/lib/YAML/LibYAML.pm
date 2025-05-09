use strict; use warnings;
package YAML::LibYAML;
our $VERSION = 'v0.904.0'; # VERSION

sub import {
    die "YAML::LibYAML has been renamed to YAML::XS. Please use YAML::XS instead.";
}

1;
