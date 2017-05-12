
=head1 NAME

Weasel::Widgets::HTML::Input - Parent of the INPUT, OPTION and BUTTON wrappers

=head1 VERSION

0.01

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

package Weasel::Widgets::HTML::Input;


use strict;
use warnings;

use Moose;
use Weasel::Element;
use Weasel::WidgetHandlers qw/ register_widget_handler /;
extends 'Weasel::Element';


register_widget_handler(
    __PACKAGE__, 'HTML',
    tag_name => 'input',
    attributes => {
        type => $_,
    })
    for (qw/ text password hidden /);

register_widget_handler(
    __PACKAGE__, 'HTML',
    tag_name => 'input',
    attributes => {
        type => undef, # default input type == 'text'
    });


=head1 METHODS

=over

=item clear()

=cut

sub clear {
    my ($self) = @_;

    $self->session->clear($self);
}

=item value([$value])

Gets the 'value' attribute; if C<$value> is provided, it is used to set the
attribute value.

=cut

sub value {
    my ($self, $value) = @_;

    $self->session->set_attribute($self, 'value', $value)
        if defined $value;

    return $self->session->get_attribute($self, 'value');
}


1;
