package UI::Various::PoorTerm::Input;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::PoorTerm::Input - concrete implementation of L<UI::Various::Input>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Input;

=head1 ABSTRACT

This module is the specific minimal fallback implementation of
L<UI::Various::Input>.  It manages and hides everything specific to the last
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

our $VERSION = '1.00';

use UI::Various::core;
use UI::Various::Input;
use UI::Various::PoorTerm::base;

require Exporter;
our @ISA = qw(UI::Various::Input UI::Various::PoorTerm::base);
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
    # Note that the accessor automatically dereferences the SCALAR here:
    print $self->_wrap($prefix, $self->textvar), "\n";
}

#########################################################################

=head2 B<_process> - handle action of UI element

    $ui_element->_process;

=head3 description:

Handle the action of the UI element aka I<the input has been selected>.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _process($)
{
    my ($self) = @_;

    # do not automatically dereference the SCALAR here:
    print $self->_wrap(msg('old_value') . ': ', ${$self->{textvar}}), "\n";
    print msg('new_value'), '? ';
    ${$self->{textvar}} = <STDIN>;
    ${$self->{textvar}} =~ s/\r?\n$//;
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Input>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
