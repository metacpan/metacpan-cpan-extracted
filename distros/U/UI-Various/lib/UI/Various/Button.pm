package UI::Various::Button;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Button - general button widget of L<UI::Various>

=head1 SYNOPSIS

    use UI::Various;
    my $main = UI::Various::main();
    $main->window(UI::Various::Button->new(text => 'Quit',
                                           code => sub{ exit(); }));
    $main->mainloop();

=head1 ABSTRACT

This module defines the general button widget of an application using
L<UI::Various>.

=head1 DESCRIPTION

Besides the common attributes inherited from C<UI::Various::widget> the
C<Button> widget knows the following additional attributes:

=head2 Attributes

=over

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.41';

use UI::Various::core;
use UI::Various::widget;
BEGIN  {  require 'UI/Various/' . UI::Various::core::using() . '/Button.pm';  }

require Exporter;
our @ISA = qw(UI::Various::widget);
our @EXPORT_OK = qw();

#########################################################################

=item code [rw, recommended]

the command invoked by the button

Note that the command gets a reference to the top-level widget (C<Window> or
C<Dialog>) as first and a reference to itself as second parameter.  This is
especially useful to end a dialogue, as those might not return a usable
reference on creation, e.g. in C<Curses>.

=cut

sub code($;$)
{
    return access('code',
		  sub{
		      unless (ref($_) eq 'CODE')
		      {
			  error('_1_attribute_must_be_a_2_reference',
				'code', 'CODE');
			  return undef;
		      }
		  },
		  @_);
}

=item text [rw, recommended]

the text of the button as string or variable reference

=cut

sub text($;$)
{
    return access('text', undef, @_);
}

#########################################################################
#
# internal constants and data:

use constant ALLOWED_PARAMETERS =>
    (UI::Various::widget::COMMON_PARAMETERS, qw(text code));
use constant DEFAULT_ATTRIBUTES => (text => '', code => sub{} );

#########################################################################
#########################################################################

=back

=head1 METHODS

Besides the accessors (attributes) described above and by
L<UI::Various::widget|UI::Various::widget/Attributes> and the methods
inherited from L<UI::Various::widget|UI::Various::widget/METHODS> only the
constructor is provided by the C<Button> class itself:

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

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
