
=head1 NAME

Weasel::Widgets::HTML::Select - Wrapper of SELECT tag

=head1 VERSION

0.01

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

package Weasel::Widgets::HTML::Select;


use strict;
use warnings;

use Moose;
use Weasel::Element;
use Weasel::WidgetHandlers qw/ register_widget_handler /;
extends 'Weasel::Element';


register_widget_handler(
    __PACKAGE__, 'HTML',
    tag_name => 'select',
    );


=head1 METHODS

=over

=item find_option()

Returns 

=cut


# 
sub _option_popup {
    my ($self) = @_;

    return $self;
}


sub find_option {
    my ($self, $text) = @_;
    my $popup = $self->_option_popup;

    return $popup->find('*option', text => $text);
}


=item select_option

=cut

sub select_option {
    my ($self, $text) = @_;

    $self->find_option($text)->click;
}


1;
