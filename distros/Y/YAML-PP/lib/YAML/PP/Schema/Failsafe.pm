use strict;
use warnings;
package YAML::PP::Schema::Failsafe;

our $VERSION = '0.013'; # VERSION

use YAML::PP::Common qw/ YAML_QUOTED_SCALAR_STYLE /;

sub register {
    my ($self, %args) = @_;

    return;
}

1;
