
=head1 NAME

Weasel::Widgets::HTML::Selectable - Wrapper for selectable elements

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $selectable = $session->page->find('./option');
  $selectable->selected(1);   # select option

=head1 DESCRIPTION


=cut

package Weasel::Widgets::HTML::Selectable;


use strict;
use warnings;

use Moose;
use Weasel::Widgets::HTML::Input;
use Weasel::WidgetHandlers qw/ register_widget_handler /;

extends 'Weasel::Widgets::HTML::Input';

register_widget_handler(
    __PACKAGE__, 'HTML',
    tag_name => 'input',
    attributes => {
        type => $_,
    })
    for (qw/ radio checkbox /);

register_widget_handler(
    __PACKAGE__, 'HTML',
    tag_name => 'option',
    );

=head1 METHODS

=over

=item selected([$value])

Returns selected status of the element. If C<$value> is provided,
sets the selected status.

=cut

sub selected {
    my ($self, $value) = @_;

    $self->session->set_attribute($self, 'selected', $value)
        if defined $value;

    return $self->session->get_attribute($self, 'selected');
}

=item get_attribute($name)

Returns the value of the attribute; when the element is I<not> selected,
the 'value' attribute is overruled to return C<false> (an empty string).

=cut

sub get_attribute {
    my ($self, $name) = @_;

    if ($name eq 'value' && ! $self->selected) {
        return ''; # false/ not selected
    }
    else {
        return $self->SUPER::get_attribute($name);
    }
}

=back

=cut

1;
