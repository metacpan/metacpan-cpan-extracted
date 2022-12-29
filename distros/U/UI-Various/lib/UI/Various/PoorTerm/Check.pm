package UI::Various::PoorTerm::Check;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::PoorTerm::Check - concrete implementation of L<UI::Various::Check>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Check;

=head1 ABSTRACT

This module is the specific minimal fallback implementation of
L<UI::Various::Check>.  It manages and hides everything specific to the last
resort UI.

=head1 DESCRIPTION

The documentation of this module is only intended for developers of the
package itself.

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.37';

use UI::Various::core;
use UI::Various::Check;
use UI::Various::PoorTerm::base;

require Exporter;
our @ISA = qw(UI::Various::Check UI::Various::PoorTerm::base);
our @EXPORT_OK = qw();

#########################################################################
#########################################################################

=head1 METHODS

=cut

#########################################################################

=head2 B<_show> - print UI element

    $ui_element->_show($prefix);

=head3 example:

    $_->_show('(1) ');

=head3 parameters:

    $prefix             text in front of first line

=head3 description:

Show (print) the UI element.  I<The method should only be called from
UI::Various::PoorTerm container elements!>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _show($$)
{
    my ($self, $prefix) = @_;
    # Note that the accessors automatically dereference the SCALARs here:
    local $_ = $prefix . '[' . ($self->var ? 'X' : ' ') . '] ';
    print $self->_wrap($_, $self->text), "\n";
}

#########################################################################

=head2 B<_process> - handle action of UI element

    $ui_element->_process;

=head3 description:

Handle the action of the UI element (invert the checkbox).

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _process($)
{
    my ($self) = @_;

    # only dereference reading the SCALAR:
    ${$self->{var}} = $self->var ? 0 : 1;	# invert value
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Check>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
