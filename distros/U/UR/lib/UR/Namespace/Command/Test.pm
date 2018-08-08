
# The diff command delegates to sub-commands under the adjoining directory.

package UR::Namespace::Command::Test;

use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "UR::Namespace::Command::Base",
    doc => 'tools for testing and debugging',
);

1;

