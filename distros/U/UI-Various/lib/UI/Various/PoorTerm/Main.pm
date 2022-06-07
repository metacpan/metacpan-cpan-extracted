package UI::Various::PoorTerm::Main;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::PoorTerm::Main - concrete implementation of L<UI::Various::Main>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Main;

=head1 ABSTRACT

This module is the specific minimal fallback implementation of
L<UI::Various::Main>.  It manages and hides everything specific to the last
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

our $VERSION = '0.24';

use UI::Various::core;
use UI::Various::Main;

require Exporter;
our @ISA = qw(UI::Various::Main);
our @EXPORT_OK = qw();

#########################################################################
#########################################################################

=head1 FUNCTIONS

=cut

#########################################################################

=head2 B<_init> - initialisation

    UI::Various::PoorTerm::Main::_init($self);

=head3 example:

    $_ = UI::Various::core::ui . '::Main::_init';
    {   no strict 'refs';   &$_($self);   }

=head3 parameters:

    $self               reference to object of abstract parent class

=head3 description:

Set-up the last resort UI.  (It's under L<FUNCTIONS|/FUNCTIONS> as it's
called before the object is re-blessed as C<UI::Various::PoorTerm::Main>.)

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _init($)
{
    debug(1, __PACKAGE__, '::_init');
    my ($self) = @_;
    ref($self) eq __PACKAGE__  or
	fatal('_1_may_only_be_called_from_itself', __PACKAGE__);

    my ($rows, $columns) = (24, 80); # fallback for terminal size
    # FIXME: only works on Linux, use non-core (!) Term::Size for others???
    # Note that -a as option to stty is POSIX, --all is not:
    local $_ = '' . `stty -a 2>/dev/null`; # ''. avoids undef!
    m/;\s*rows\s+([1-9][0-9]*);\s*columns\s+([1-9][0-9]*);/
	and  ($rows, $columns) = ($1, $2);
    # can't use accessors as we're not yet correctly blessed:
    $self->{max_height} = $rows;
    $self->{max_width} = $columns;
}

#########################################################################

=head1 METHODS

=cut

#########################################################################

=head2 B<mainloop> - main event loop of an application

C<PoorTerm>'s concrete implementation of
L<UI::Various::Main::mainloop|UI::Various::Main/mainloop - main event loop
of an application>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub mainloop($)
{
    my ($self) = @_;
    my $n = $self->children;
    my $i = 0;			# behave like Curses::UI and Tk: 1st comes 1st
    debug(1, __PACKAGE__, '::mainloop: ', $i, ' / ', $n);

    local $_;
    while ($n > 0)
    {
	$_ = $self->child($i)->_process;
	$n = $self->children;
	# uncoverable branch false count:4
	if (not defined $_)
	{   $i = $n - 1;   }
	elsif ($_ eq '+')
	{   $i++;   }
	elsif ($_ eq '-')
	{   $i--;   }
	elsif ($_ eq '0')
	{   $i = $n - 1;   }
	if ($i >= $n)
	{   $i = 0;   }
	elsif ($i < 0)
	{   $i = $n - 1;   }
    }
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

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
