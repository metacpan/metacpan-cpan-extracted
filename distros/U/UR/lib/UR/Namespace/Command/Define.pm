package UR::Namespace::Command::Define;

use warnings;
use strict;
use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Namespace::Command::Base',
    doc => "define namespaces, data sources and classes",
);

sub sub_command_sort_position { 2 }

sub shell_args_description { "[namespace|...]"; }

1;

