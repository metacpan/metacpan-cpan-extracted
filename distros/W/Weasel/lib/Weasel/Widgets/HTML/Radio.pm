
=head1 NAME

Weasel::Widgets::HTML::Radio - Wrapper for INPUTs of type 'radio'

=head1 VERSION

0.01

=head1 SYNOPSIS

  my $selectable = $session->page->find('*radio');
  $selectable->selected(1);   # select radio button

=head1 DESCRIPTION


=cut

=head1 DEPENDENCIES



=cut

package Weasel::Widgets::HTML::Radio;


use strict;
use warnings;

use List::Util qw/first/;

use Moose;
use Weasel::Widgets::HTML::Selectable;
use Weasel::WidgetHandlers qw/ register_widget_handler /;

extends 'Weasel::Widgets::HTML::Selectable';
use namespace::autoclean;

register_widget_handler(
    __PACKAGE__, 'HTML',
    tag_name => 'input',
    attributes => {
        type => 'radio',
    });

=head1 SUBROUTINES/METHODS

=over

=item value([$value])

=cut

sub _find_related_radios {
    my ($self) = @_;

    return $self->session->page->find_all('*radio', name => $self->get_attribute('name'));
}

sub value {
    my ($self, $new_value) = @_;

    if ($new_value) {
        $self->session->page->find('*radio',
                                   name => $self->get_attribute('name'),
                                   value => $new_value)->click;
    }

    my $selected = first { $_->selected } $self->_find_related_radios;
    return $selected ? $selected->get_attribute('value') : '';
}

=back

=cut

=head1 AUTHOR

Erik Huelsmann

=head1 CONTRIBUTORS

Erik Huelsmann

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

 (C) 2016-2023  Erik Huelsmann

Licensed under the same terms as Perl.

=cut

__PACKAGE__->meta->make_immutable;

1;

