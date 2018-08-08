package UR::Namespace::Command::Update;
use warnings;
use strict;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "UR::Namespace::Command::Base",
    doc => 'update parts of the source tree of a UR namespace'
);

sub sub_command_sort_position { 4 }

1;

