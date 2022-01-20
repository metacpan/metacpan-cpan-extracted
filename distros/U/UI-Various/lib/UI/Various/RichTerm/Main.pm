package UI::Various::RichTerm::Main;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::RichTerm::Main - concrete implementation of L<UI::Various::Main>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Main;

=head1 ABSTRACT

This module is the specific implementation of the rich terminal UI.  It
manages and hides everything specific to it.

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

our $VERSION = '0.14';

use Term::ReadLine;

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

    UI::Various::RichTerm::Main::_init($self);

=head3 example:

    $_ = UI::Various::core::ui . '::Main::_init';
    {   no strict 'refs';   &$_($self);   }

=head3 parameters:

    $self               reference to object of abstract parent class

=head3 description:

Set-up the rich terminal UI.  (It's under L<FUNCTIONS|/FUNCTIONS> as it's
called before the object is re-blessed as C<UI::Various::PoorTerm::Main>.)

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _init($)
{
    my ($self) = @_;
    local $_;
    ref($self) eq __PACKAGE__  or
	fatal('_1_may_only_be_called_from_itself', __PACKAGE__);

    # initialise ReadLine:
    my $rl = Term::ReadLine->new('UI::Various', *STDIN, *STDOUT);
    debug(1, __PACKAGE__, '::_init: ReadLine is ', $rl->ReadLine);
    $self->{_rl} = $rl;
    $rl->MinLine(3);

    # get terminal size from (GNU) ReadLine, Unix stty or fallback size 24x80:
    my ($rows, $columns) = (undef, undef);
    local $_;
    eval { ($rows, $columns) = $rl->get_screen_size };
    # We check both conditions even though they are both either undef or valid:
    # uncoverable condition right
    unless ($rows  and  $columns)
    {
	($rows, $columns) = (24, 80);
	$_ = '' . `stty -a 2>/dev/null`;	# -a is POSIX, --all is not
	m/;\s*rows\s+(\d+);\s*columns\s+(\d+);/  and
	    ($rows, $columns) = ($1, $2);
    }
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

#########################################################################

=head2 B<readline> - get readline input

    $_ = $self->top->readline($prompt, $re_allowed, $initial_value);

=head3 parameters:

    $self               reference to object
    $prompt             string for the prompt
    $re_allowed         regular expression for allowed values
    $initial_value      initial value for input and flag for RL history

=head3 description:

Prompt for input and get line from L<Term::ReadLine>.  The line will be
checked against the regular expression.  Input is read over again until a
valid input is obtained, which is then returned.  If the optional initial
value is set, it will be used passed as 2nd parameter to C<readline>
(I<PREPUT> argument).  It also activates storing a valid input in
L<ReadLine's|Term::ReadLine> history.

=head3 returns:

valid input

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub readline($$$;$)
{
    my ($self, $prompt, $re_allowed, $initial_value) = @_;
    local $_ = undef;

    do
    {{
	$_ = $self->{_rl}->readline($prompt, $initial_value);
	# This can only happen with non-interactive input, therefore we use
	# die instead of fatal:
	defined $_  or  die msg('undefined_input');
	unless (m/$re_allowed/)
	{   error('invalid_selection');   next;   }
	if ($initial_value)
	{   $self->{_rl}->addhistory($_);   }
	s/\r?\n$//;
    }} until m/$re_allowed/;
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
