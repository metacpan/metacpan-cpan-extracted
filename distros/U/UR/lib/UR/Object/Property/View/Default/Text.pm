package UR::Object::Property::View::Default::Text;

use strict;
use warnings;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Object::View::Default::Text',
    has => [
       default_aspects => { is => 'ARRAY', is_constant => 1,
                            value => ['class_name', 'property_name','data_type', 'is_optional'], },
    ],
);


1;

=pod

=head1 NAME

UR::Object::Property::View::Default::Text - View class for UR::Object::Property

=head1 DESCRIPTION

Used by UR::Namespace::Command::Info when displaying information about a property

=cut
