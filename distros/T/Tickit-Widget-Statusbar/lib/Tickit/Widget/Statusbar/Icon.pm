package Tickit::Widget::Statusbar::Icon;

use strict;
use warnings;

our $VERSION = '0.005'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use parent qw(Tickit::Widget);

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

sub new {
    my $self = shift->SUPER::new;
    my %args = @_;
    $self->set_icon(delete $args{icon}) if exists $args{icon};
    $self;
}

sub cols { 1 }

sub lines { 1 }

sub icon { shift->{icon} }

sub set_icon {
    my $self = shift;
    $self->{icon} = shift;
    $self->redraw;
    $self
}

sub render_to_rb {
    my $self = shift;
    my $rb = shift;

    $rb->goto(0, 0);
    $rb->text($self->icon);
}

1;
