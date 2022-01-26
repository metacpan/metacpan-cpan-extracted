package UI::Various::Input;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Input - general input widget of L<UI::Various>

=head1 SYNOPSIS

    use UI::Various;
    my $main = UI::Various::main();
    my $input = 'enter name';
    $main->window(...
                  UI::Various::Input->new(textvar => $input),
                  ...);
    $main->mainloop();

=head1 ABSTRACT

This module defines the general input widget of an application using
L<UI::Various>.

=head1 DESCRIPTION

Besides the common attributes inherited from C<UI::Various::widget> the
C<Input> widget knows only one additional attribute:

Note that currently only single line input fields with visible text (no
passwords!) are supported.

=head2 Attributes

=over

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.15';

use UI::Various::core;
use UI::Various::widget;
BEGIN  {  require 'UI/Various/' . UI::Various::core::using() . '/Input.pm';  }

require Exporter;
our @ISA = qw(UI::Various::widget);
our @EXPORT_OK = qw();

#########################################################################

=item textvar [rw]

a variable reference for the input field

The content of the variable will be displayed and can be modified through
the input field.

=cut

sub textvar($;$)
{
    defined $_[1]  or  return get('textvar', @_);
    # explicit check for SCALAR reference when used as setter (needed here
    # as SCALAR references are treated special in set/access):
    unless (ref($_[1]) eq 'SCALAR')
    {
	error('_1_attribute_must_be_a_2_reference',
	      'textvar', 'SCALAR');
	return undef;
    }
    return set('textvar', undef, @_);
}

#########################################################################
#
# internal constants and data:

use constant ALLOWED_PARAMETERS =>
    (UI::Various::widget::COMMON_PARAMETERS, qw(textvar));
use constant DEFAULT_ATTRIBUTES =>
    (textvar => UI::Various::core::dummy_varref());

#########################################################################
#########################################################################

=back

=head1 METHODS

Besides the accessors (attributes) described above and by
L<UI::Various::widget|UI::Various::widget/Attributes> and the methods
inherited from L<UI::Various::widget|UI::Various::widget/METHODS> only the
constructor is provided by the abstract C<Input> class itself:

=cut

#########################################################################

=head2 B<new> - constructor

see L<UI::Various::core::construct|UI::Various::core/construct - common
constructor for UI elements>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub new($;\[@$])
{
    debug(3, __PACKAGE__, '::new');
    return construct({ DEFAULT_ATTRIBUTES },
		     '^(?:' . join('|', ALLOWED_PARAMETERS) . ')$',
		     @_);
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner@cpan.orgE<gt>

=cut
