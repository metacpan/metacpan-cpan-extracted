package UI::Various::Main;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Main - general main "Window Manager" class of L<UI::Various>

=head1 SYNOPSIS

    use UI::Various;
    my $main = UI::Various::main();
    $main->window(...);
    $main->mainloop();

=head1 ABSTRACT

This module defines the general main "Window Manager" class of an
application using L<UI::Various>.  It keeps track of active / inactive
windows and / or the active dialogue.  In addition it manages global
attributes of the current UI, e.g. size of the display.

=head1 DESCRIPTION

L<UI::Various>'s "Window Manager" is a singleton keeping track of all
windows and dialogues of the application.  It takes care of setting them up
for the currently used UI and removing them when they are no longer needed.
In addition it triggers the event loops of the current UI (aka their main
loops).

In addition it holds some convenience methods to ease creating windows and
some specific dialogues (see L<METHODS|/METHODS> below).

The "Window Manager" holds the following attributes (besides those inherited
from C<UI::Various::widget>):

=head2 Attributes

=over

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.20';

use UI::Various::core;
use UI::Various::container;
BEGIN  {  require 'UI/Various/' . UI::Various::core::using() . '/Main.pm';  }

require Exporter;
our @ISA = qw(UI::Various::container);
our @EXPORT_OK = qw();

my $self = undef;		# UI::Various::Main's singleton!

#########################################################################

=item max_height [ro]

maximum height of an application window in (approximately) characters as
defined by the underlying UI system and screen / terminal size

=cut

sub max_height($)		# 'public' getter
{
    return get('max_height', $self);
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

=item max_width [ro]

maximum width of an application window in (approximately) characters as
defined by the underlying UI system and screen / terminal size

=cut

sub max_width($)		# 'public' getter
{
    return get('max_width', $self);
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

=back

=head3 modified attributes

The following attribute behave slightly different from their general
description in L<widget|UI::Various::widget>.  First of all (except for
initialisation) they always ignore the passed object and use the internal
singleton object instead.  In addition they are no longer B<inherited> but
B<optional> or mandatory, as the main "Window Manager" is the one object
defining the defaults for all others that do not set them.

=over

=item L<height|UI::Various::widget/height rw, inherited> [rw, optional]

=item L<width|UI::Various::widget/width rw, inherited> [rw, optional]

=back

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub height($;$)
{
    local $_ = shift;
    # ignore probably wrong pointer to singleton after initialisation:
    defined $self  and  $_ = $self;
    $_->SUPER::height(@_);
}

sub width($;$)
{
    local $_ = shift;
    # ignore probably wrong pointer to singleton after initialisation:
    defined $self  and  $_ = $self;
    $_->SUPER::width(@_);
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

=pod

Note that all accessor methods can also be called via the package name
itself, e.g. C<UI::Various::Main::max_width()>.  As the "Window Manager" is
a singleton, it always accesses the sole existing instance anyway.

=cut

#########################################################################
#
# internal constants and data:

use constant ALLOWED_PARAMETERS => UI::Various::widget::COMMON_PARAMETERS;
use constant DEFAULT_ATTRIBUTES => (max_height => undef,
				    max_width => undef);

#########################################################################
#########################################################################

=head1 METHODS

Besides the accessors (attributes) described above and by
L<UI::Various::widget|UI::Various::widget/Attributes> as well as the methods
inherited from L<UI::Various::widget|UI::Various::widget/METHODS> and
L<UI::Various::container|UI::Various::container/METHODS>, the following
additional methods are provided by the main "Window Manager" class itself:

=cut

#########################################################################

=head2 B<new> - constructor

see L<UI::Various::core::construct|UI::Various::core/construct - common
constructor for UI elements>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub new($;\[@$])
{
    debug(1, __PACKAGE__, '::new');
    unless (defined $self)
    {
	$self = construct({ (DEFAULT_ATTRIBUTES) },
			  '^(?:' . join('|', ALLOWED_PARAMETERS) . ')$',
			  @_);
	$self->{ui} = UI::Various::core::ui();
	$self->_init;
	if (not defined $self->{height}  or
	    $self->{height} > $self->{max_height})
	{   $self->{height} = $self->{max_height};   }
	if (not defined $self->{width}  or
	    $self->{width} > $self->{max_width})
	{   $self->{width} = $self->{max_width};   }
	debug(1, __PACKAGE__, '::new: ',
	      $self->{width}, 'x', $self->{height}, ' / ',
	      $self->{max_width}, 'x', $self->{max_height});
    }
    return $self;
}

#########################################################################

=head2 B<window> - add new window to application

    $window = $main->window([$rh_attributes,] @ui_elements);

=head3 example:

    $main->window(UI::Various::Text->new(text => 'Hello World!'),
                  UI::Various::Button->new(text => 'Quit',
                                           code => sub{ exit(); }));

=head3 parameters:

    $rh_attributes      optional reference to hash with attributes
    @ui_elements        array with possible UI elements of a window

=head3 description:

Add a new window to the application.  An optional attribute HASH is passed
on to the created window while optional other UI elements are added in the
specified sequence.

=head3 returns:

the new window or undef in case of an error

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub window($@)
{
    debug(2, __PACKAGE__, '::window');
    my $self = shift;
    local $_;

    my @ui_elements = ();
    my $rh_attributes = {};
    while ($_ = shift)
    {
	if (ref($_) eq 'HASH')
	{
	    $rh_attributes = $_; # last definition wins!
	}
	elsif ($_->isa('UI::Various::widget'))
	{
	    if ($_->isa('UI::Various::Window')  or
		$_->isa('UI::Various::Dialog'))
	    {
		error('invalid_object__1_in_call_to__2__3',
		      ref($_), __PACKAGE__, 'window');
		return undef;
	    }
	    push @ui_elements, $_;
	}
	else
	{
	    error('invalid_parameter__1_in_call_to__2__3',
		  ref($_), __PACKAGE__, 'window');
	    return undef;
	}
    }
    my $window = UI::Various::Window->new($rh_attributes);
    $window->add($_) foreach @ui_elements;
    return $window;
}

#########################################################################

=head2 B<dialog> - add new dialogue to application

    $dialog = $main->dialog([$rh_attributes,] @ui_elements);

=head3 example:

    $main->dialog(UI::Various::Text->new(text => 'Hello World!'),
                  UI::Various::Button->new(text => 'Quit',
                                           code => sub{ exit(); }));

=head3 parameters:

    $rh_attributes      optional reference to hash with attributes
    @ui_elements        array with possible UI elements of a dialogue

=head3 description:

Add a new dialogue to the application.  An optional attribute HASH is passed
on to the created dialogue while optional other UI elements are added in the
specified sequence.

Note that in C<Curses> the call blocks until the dialogue has finished!  (It
will therefore return C<undef> in those cases.)

=head3 returns:

the new dialogue or undef in case of an error (and always in C<Curses>)

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub dialog($@)
{
    debug(2, __PACKAGE__, '::dialog');
    my $self = shift;
    local $_;

    my @ui_elements = ();
    my $rh_attributes = {};
    while ($_ = shift)
    {
	if (ref($_) eq 'HASH')
	{
	    $rh_attributes = $_; # last definition wins!
	}
	elsif ($_->isa('UI::Various::widget'))
	{
	    if ($_->isa('UI::Various::Window')  or
		$_->isa('UI::Various::Dialog'))
	    {
		error('invalid_object__1_in_call_to__2__3',
		      ref($_), __PACKAGE__, 'dialog');
		return undef;
	    }
	    push @ui_elements, $_;
	}
	else
	{
	    error('invalid_parameter__1_in_call_to__2__3',
		  ref($_), __PACKAGE__, 'dialog');
	    return undef;
	}
    }
    my $dialog = UI::Various::Dialog->new($rh_attributes);
    $dialog->add($_) foreach @ui_elements;
    return $dialog;
}

#########################################################################

=head2 B<mainloop> - main event loop of an application

    $main->mainloop();

=head3 description:

The main event loop of the application, handling every
C<L<Window|UI::Various::Window>> and C<L<Dialog|UI::Various::Dialog>> until
none is left or the application exits.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub mainloop($)
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
