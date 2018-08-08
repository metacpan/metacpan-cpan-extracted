package UR::Object::View::Toolkit::Text;

use warnings;
use strict;
require UR;

our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Object::View::Toolkit',
    has => [
        toolkit_name    => { is_constant => 1, value => "text" },
        toolkit_module  => { is_constant => 1, value => "(none)" },  # is this used anywhere?
    ]
);

sub show_view {
    my $class = shift;
    my $view = shift;
    my $widget = $view->widget;
    return $$widget;
}

# This doesn't really apply for text?!
sub hide_view {
return undef;

    my $class = shift;
    my $view = shift;
    my $widget = $view->widget;
    print "DEL: $widget\n";
    return 1;
}

# This doesn't really apply for text?!
sub create_window_for_view {
return undef;

    my $class = shift;
    my $view = shift;
    my $widget = $view->widget;
    print "WIN: $widget\n";
    return 1;
}

# This doesn't really apply for text?!
sub delete_window_around_view {
return undef;

    my $class = shift;
    my $widget = shift; 
    print "DEL: $widget\n";
    return 1;
}

1;

=pod

=head1 NAME

UR::Object::View::Toolkit::Text - Declaration of Text as a View toolkit type

=head1 SYNOPSIS

Methods called by UR::Object::View to get toolkit specific support for
common tasks.

=cut


