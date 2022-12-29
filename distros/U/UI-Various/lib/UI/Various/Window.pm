package UI::Various::Window;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Window - general top-level window widget of L<UI::Various>

=head1 SYNOPSIS

    use UI::Various;
    my $main = UI::Various::main();
    my $window = $main->window();
    $window->add(UI::Various::Text->new(text => 'Hello World!'));
    ...
    $main->mainloop();

=head1 ABSTRACT

This module defines the general (main) window object of an application using
L<UI::Various>.

=head1 DESCRIPTION

Besides the common attributes inherited from C<UI::Various::widget> and
C<UI::Various::toplevel> the C<Window> widget knows the following
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

our $VERSION = '0.37';

use UI::Various::core;
use UI::Various::toplevel;
BEGIN  {  require 'UI/Various/' . UI::Various::core::using() . '/Window.pm';  }

require Exporter;
our @ISA = qw(UI::Various::toplevel);
our @EXPORT_OK = qw();

#########################################################################

=item title [rw, fixed, optional]

an optional title string for the window as string or variable reference

=cut

sub title($;$)
{
    return access('title', undef, @_);
}

#########################################################################
#
# internal constants and data:

use constant ALLOWED_PARAMETERS =>
    (UI::Various::widget::COMMON_PARAMETERS, qw(title));
use constant DEFAULT_ATTRIBUTES => (title => '');

#########################################################################
#########################################################################

=back

=head1 METHODS

Besides the accessors (attributes) described above and the attributes and
methods of L<UI::Various::widget>, L<UI::Various::container> and
L<UI::Various::toplevel>, the following additional methods are provided by
the C<Window> class itself:

=cut

#########################################################################

=head2 B<new> - constructor

see L<UI::Various::core::construct|UI::Various::core/construct - common
constructor for UI elements>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub new($;\[@$])
{
    debug(2, __PACKAGE__, '::new');
    my $self = construct({ DEFAULT_ATTRIBUTES },
			 '^(?:' . join('|', ALLOWED_PARAMETERS) . ')$',
			 @_);
    # Get "Window Manager" singleton even if it is not yet existing:
    local $_ = UI::Various::Main->new();
    $_->add($self);
    return $self;
}

#########################################################################

=head2 B<destroy> - remove window from application

    $window->destroy();

=head3 description:

C<destroy> removes the window and all its UI elements from the application
(and its L<main "Window Manager" singleton|UI::Various::Main>), hopefully
freeing all memory used by the UI.  (This may vary depending on the
underlying UI package used.)  If the window was the last one of the
application, this also causes the C<L<main loop|UI::Various::Main/mainloop
- main event loop of an application>> to be finished.

Note that a window can not be reused again after destruction as it's broken
down into its components to get rid of circular dependencies that may block
clean-up of memory.  If you want to open the same window again, you have to
recreate it.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub destroy($)
{   fatal('specified_implementation_missing');   }

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
