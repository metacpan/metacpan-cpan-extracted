package UR::Namespace::Command;

# This is the module behind the "ur" executable.

use strict;
use warnings;
use UR;
use UR::Namespace::Command::Base;

our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'Command',
    doc => 'tools to create and maintain a ur class tree'
);

1;

