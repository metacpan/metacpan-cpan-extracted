package UR::Object::Type::View::Default::Text;

use strict;
use warnings;
require UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Object::View::Default::Text',
    has => [
       default_aspects => { is => 'ARRAY', is_constant => 1, value => ['is','direct_property_names'], },
    ],
);


1;

=pod

=head1 NAME

UR::Object::Type::View::Default::Text - View class for class metaobjects

=head1 DESCRIPTION

This class is used by L<UR::Namespace::Command::Info> and L<UR::Namespace::Command::Description>
to construct the text outputted.

=cut
