package Tickit::Widget::Statusbar::Icon;

use strict;
use warnings;

our $VERSION = '0.006'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use Object::Pad;
class Tickit::Widget::Statusbar::Icon :isa(Tickit::Widget);

use utf8;

=encoding utf8

=head1 NAME

Tickit::Widget::Statusbar::Icon - an icon on the status bar

=head1 DESCRIPTION

Provides icons on the status bar. An icon is a short text
string (typically a single Unicode character).

=cut

use constant CLEAR_BEFORE_RENDER => 0;
use constant WIDGET_PEN_FROM_STYLE => 1;
use constant CAN_FOCUS => 0;
use Tickit::Style;

BEGIN {
    style_definition ':error' =>
        fg => 196;
    style_definition ':ok' =>
        fg => 42;
}

BUILD (%args) {
    $self->set_icon(delete $args{icon}) if exists $args{icon};
    $self;
}

method cols { 1 }

method lines { 1 }

method icon { $self->{icon} }

method set_icon ($icon) {
    $self->{icon} = $icon;
    $self->redraw;
    $self
}

method render_to_rb ($rb, @) {
    $rb->goto(0, 0);
    $rb->text($self->icon);
}

1;
