
=pod

=head1 NAME

UR::Object::View::Toolkit 

=head1 SYNOPSIS

$v1 = $obj->create_view(toolkit => "gtk");
$v2 = $obj->create_view(toolkit => "tk");

is($v1->_toolkit_delegate, "UR::Object::View::Toolkit::Gtk");
is($v2->_toolkit_delegate, "UR::Object::View::Toolkit::Tk");

=head1 DESCRIPTION

Each view delegates to one of these to interact with the toolkit environment

=cut

package UR::Object::View::Toolkit;

use warnings;
use strict;
our $VERSION = "0.47"; # UR $VERSION;

require UR;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Singleton',
    is_abstract => 1,
    has => [
        toolkit_name    =>  { is_abstract => 1, is_constant => 1 },
        toolkit_module  =>  { is_abstract => 1, is_constant => 1 },
    ],
);  

1;
