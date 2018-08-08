
package UR::Namespace::Command::Old::DiffUpdate;

use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "UR::Namespace::Command::Base",
);

sub help_description { 
    "Show the differences between class schema and database schema."
}

*for_each_class_object = \&UR::Namespace::Command::Diff::for_each_class_object_delegate_used_by_sub_commands;

1;
