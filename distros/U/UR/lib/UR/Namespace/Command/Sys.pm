package UR::Namespace::Command::Sys;
use warnings;
use strict;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Namespace::Command::Base',
    doc => 'service launchers'
);

1;
