package UR::Namespace::Command::Old;

use warnings;
use strict;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Namespace::Command::Base',
    doc => "deprecated commands for namespaces, data sources and classes",
);

sub _is_hidden_in_docs { 1 }

sub shell_args_description { "[namespace|...]"; }

1;

