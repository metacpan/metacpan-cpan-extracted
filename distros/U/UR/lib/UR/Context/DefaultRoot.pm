package UR::Context::DefaultRoot;
use strict;
use warnings;

require UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::Context::DefaultRoot',
    is => ['UR::Context::Root'],
    doc => 'The base context used when no special base context is specified.',
);

1;

=pod

=head1 NAME

UR::Context::DefaultRoot - The base context used when no special base context is specified

=cut
