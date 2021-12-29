package UI::Various::Tk::Main;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Tk::Main - concrete implementation of L<UI::Various::Main>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Main;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Main> for
L<Perl-Tk|Tk>.  It manages and hides everything specific to L<Tk>.

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

our $VERSION = '0.09';

use UI::Various::core;
use UI::Various::Main;

require Exporter;
our @ISA = qw(UI::Various::Main);
our @EXPORT_OK = qw();

use Tk;

#########################################################################
#########################################################################

=head1 FUNCTIONS

=cut

#########################################################################

=head2 B<_init> - initialisation

    UI::Various::Tk::Main::_init($self);

=head3 example:

    $_ = UI::Various::core::ui . '::Main::_init';
    {   no strict 'refs';   &$_($self);   }

=head3 parameters:

    $self               reference to object of abstract parent class

=head3 description:

Prepare the interface to L<Tk>.  (It's under L<FUNCTIONS|/FUNCTIONS> as it's
called before the object is re-blessed as C<UI::Various::Tk::Main>.)

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _init($)
{
    debug(2, __PACKAGE__, '::_init');
    my ($self) = @_;
    ref($self) eq 'UI::Various::Main'  or
	fatal('_1_may_only_be_called_from__2', __PACKAGE__, 'UI::Various::Main');

    # use dummy window to get some Window Manager details:
    local $_ = MainWindow->new();
    my ($screen_width, $screen_height) = $_->maxsize;

    # heuristic as elements may have different height (especially buttons!):
    my $char_height = abs($_->fontActual('', '-size')) - 1;
    my $rows = $screen_height / $char_height + 1;

    my $char_width = 10;
    foreach my $c (ord('!')..ord('~'))
    {				# find width of widest ASCII character:
	my $w = $_->fontMeasure('', chr($c));
	$char_width >= $w  or  $char_width = $w;
    }
    # heuristic: use 3/4 of widest character and round down columns:
    $char_width *= 3 / 4;
    my $columns = $screen_width / $char_width;

    $_->destroy;
    $_ = undef;

    # can't use accessors as we're not yet correctly blessed:
    $self->{max_height} = int($rows);
    $self->{max_width} = int($columns);
    # we need those to be able to calculate pixel sizes:
    $self->{_char_height} = $char_height;
    $self->{_char_width} = $char_width;
    # internal flag if Tk's mainloop is currently running:
    $self->{_running} = 0;
}

#########################################################################

=head1 METHODS

=cut

#########################################################################

=head2 B<mainloop> - main event loop of an application

C<Tk>'s concrete implementation of
L<UI::Various::Main::mainloop|UI::Various::Main/mainloop - main event loop
of an application>

It is split into two internal functions for unit testing.  (It will not be
called that often to make this a performance issue. :-)

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub mainloop($)
{
    debug(1, __PACKAGE__, '::mainloop');
    _mainloop_prepare($_[0]);
    _mainloop_run($_[0]);
}
sub _mainloop_prepare($)
{
    my ($self) = @_;
    local $_;
    while ($_ = $self->child)
    {   $_->_prepare;   }
    $self->{_running} = 1;
}
sub _mainloop_run($)
{
    my ($self) = @_;
    MainLoop;
    $self->{_running} = 0;
    # TODO: How to handle windows added later??? overload add, SUPER::add
}

#########################################################################

=head2 B<window> - and new window to application

C<Tk>'s overload of L<UI::Various::Main::window|UI::Various::Main/window -
and new window to application>.  If the C<Mainloop> of L<Tk> is running, we
need to directly prepare and show the window / dialogue.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub window($@)
{
    debug(2, __PACKAGE__, '::window');
    my $self = shift;
    local $_ = $self->SUPER::window(@_);
    if ($self->{_running})
    {   $_->_prepare;   }
    return $_;
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Main>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner@cpan.orgE<gt>

=cut
