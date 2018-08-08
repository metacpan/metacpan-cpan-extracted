package UR::Namespace::Command::List;
use warnings;
use strict;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "UR::Namespace::Command::Base",
    doc => "list objects, classes, modules"
);

sub sub_command_sort_position { 5 }

1;

