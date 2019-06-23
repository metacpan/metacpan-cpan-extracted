
=head1 NAME

Weasel::Widgets::HTML::Selectable - Wrapper for selectable elements

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $selectable = $session->page->find('./option');
  $selectable->selected(1);   # select option

=head1 DESCRIPTION


=cut

=head1 DEPENDENCIES



=cut

package Weasel::Widgets::HTML::Selectable;


use strict;
use warnings;

use Moose;
use Weasel::Widgets::HTML::Input;
use Weasel::WidgetHandlers qw/ register_widget_handler /;

extends 'Weasel::Widgets::HTML::Input';
use namespace::autoclean;

register_widget_handler(
    __PACKAGE__, 'HTML',
    tag_name => 'input',
    attributes => {
        type => 'checkbox',
    });


register_widget_handler(
    __PACKAGE__, 'HTML',
    tag_name => 'option',
    );

=head1 SUBROUTINES/METHODS

=over

=item selected([$value])

Returns selected status of the element. If C<$value> is provided,
sets the selected status.

=cut

sub selected {
    my ($self, $new_value) = @_;

    if (defined $new_value) {
        my $selected = $self->session->get_attribute($self, 'selected');
        if (! $new_value && $selected) {
            $self->click; # unselect
        }
        elsif ($new_value && ! $selected) {
            $self->click; # select
        }
    }
    return $self->session->get_attribute($self, 'selected');
}

=item value([$new_value])

Returns the value of the 'value' attribute; when the element is I<not> selected,
the 'value' attribute is overruled to return C<false> (an empty string).

=cut

sub value {
    my ($self, $new_value) = @_;

    if (! $self->selected($new_value)) {
        return ''; # false/ not selected
    }
    else {
        return $self->get_attribute('value');
    }
}

=back

=cut

=head1 AUTHOR

Erik Huelsmann

=head1 CONTRIBUTORS

Erik Huelsmann
Yves Lavoie

=head1 MAINTAINERS

Erik Huelsmann

=head1 BUGS AND LIMITATIONS

Bugs can be filed in the GitHub issue tracker for the Weasel project:
 https://github.com/perl-weasel/weasel/issues

=head1 SOURCE

The source code repository for Weasel is at
 https://github.com/perl-weasel/weasel

=head1 SUPPORT

Community support is available through
L<perl-weasel@googlegroups.com|mailto:perl-weasel@googlegroups.com>.

=head1 LICENSE AND COPYRIGHT

 (C) 2016  Erik Huelsmann

Licensed under the same terms as Perl.

=cut

__PACKAGE__->meta->make_immutable;

1;

