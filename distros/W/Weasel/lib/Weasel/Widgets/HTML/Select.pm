
=head1 NAME

Weasel::Widgets::HTML::Select - Wrapper of SELECT tag

=head1 VERSION

0.02

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 DEPENDENCIES



=cut

package Weasel::Widgets::HTML::Select;


use strict;
use warnings;

use List::Util qw/first/;
use Moose;
use Weasel::Element;
use Weasel::WidgetHandlers qw/ register_widget_handler /;
extends 'Weasel::Element';
use namespace::autoclean;

register_widget_handler(
    __PACKAGE__, 'HTML',
    tag_name => 'select',
    );


=head1 SUBROUTINES/METHODS

=over

=item find_option()

Returns

=cut


#
sub _option_popup {
    my ($self) = @_;

    return $self;
}

=item find_option

=cut

sub find_option {
    my ($self, $text) = @_;
    my $popup = $self->_option_popup;

    return $popup->find('*option', text => $text);
}

=item find_options

=cut

sub find_options {
    my ($self) = @_;
    my $popup = $self->_option_popup;

    return $popup->find_all('*option');
}

=item select_option

=cut

sub select_option {
    my ($self, $text) = @_;

    return $self->find_option($text)->click;
}

=item value([ $new_value ])

=cut

sub value {
    my ($self, $new_value) = @_;

    if ($new_value) {
        $self->select_option($new_value);
    }
    my $option = first { $_->selected } $self->find_options;
    return $option ? $option->get_attribute('value') : undef;
}

=item values([@new_values])

=cut

sub values {
    my ($self, @new_values) = @_;

    if (@new_values) {
        $self->select_option($_)
            for @new_values;
    }
    my @options = grep { $_->selected } $self->find_options;
    return map { $_->get_attribute('value') } @options;
}

=back

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

 (C) 2016-2023  Erik Huelsmann

Licensed under the same terms as Perl.

=cut

__PACKAGE__->meta->make_immutable;

1;

