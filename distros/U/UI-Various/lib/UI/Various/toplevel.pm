package UI::Various::toplevel;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::toplevel - abstract top-level widget of L<UI::Various>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following ones:
    use UI::Various::Window;
    use UI::Various::Dialog;

=head1 ABSTRACT

This module is the common abstract container class for the top-level UI
 elements C<L<UI::Various::Window>> and C<L<UI::Various::Dialog>>.

=head1 DESCRIPTION

Besides the common attributes inherited from C<UI::Various::widget> and
C<UI::Various::container> the C<toplevel> widget knows the following
additional attributes:

=head2 Attributes

=over

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.13';

use UI::Various::core;
use UI::Various::container;

require Exporter;
our @ISA = qw(UI::Various::container);
our @EXPORT_OK = qw();

#########################################################################

=item height [rw]

preferred (maximum) height of an application window / dialogue in
(approximately) characters, should not exceed L<max_height of main "Window
Manager" |UI::Various::Main/max_height ro>

=cut

sub height($;$)
{
    return access('height', undef, @_);
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

=item max_height [ro, inherited]

access to L<max_height of main "Window Manager"|UI::Various::Main/max_height
ro>

=cut

sub max_height($;$)
{
    return UI::Various::widget::_inherited_access('max_height', undef, @_);
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

=item max_width [ro, inherited]

access to L<max_width of main "Window Manager" |UI::Various::Main/max_width
ro>

=cut

sub max_width($;$)
{
    return UI::Various::widget::_inherited_access('max_width', undef, @_);
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

=item width [rw]

preferred (maximum) width of an application window in (approximately)
characters, may not exceed L<max_width of main "Window Manager"
|UI::Various::Main/max_width ro>

=cut

sub width($;$)
{
    return access('width', undef, @_);
}

#########################################################################

1;

#########################################################################
#########################################################################

=back

=head1 SEE ALSO

L<UI::Various>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner@cpan.orgE<gt>

=cut
