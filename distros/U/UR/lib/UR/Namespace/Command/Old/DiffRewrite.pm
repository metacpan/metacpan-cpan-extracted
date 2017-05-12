
package UR::Namespace::Command::Old::DiffRewrite;

use strict;
use warnings;
use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "UR::Namespace::Command::Base",
);

sub help_description { 
    "Show the differences between current class headers and the results of a rewrite." 
}

*for_each_class_object = \&UR::Namespace::Command::Diff::for_each_class_object_delegate_used_by_sub_commands;

1;

