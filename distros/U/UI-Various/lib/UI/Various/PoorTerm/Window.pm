package UI::Various::PoorTerm::Window;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::PoorTerm::Window - concrete implementation of L<UI::Various::Window>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Window;

=head1 ABSTRACT

This module is the specific minimal fallback implementation of
L<UI::Various::Window>.  It manages and hides everything specific to the last
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

our $VERSION = '0.18';

use UI::Various::core;
use UI::Various::Window;
use UI::Various::PoorTerm::container;

require Exporter;
our @ISA = qw(UI::Various::Window UI::Various::PoorTerm::container);
our @EXPORT_OK = qw();

#########################################################################
#########################################################################

=head1 METHODS

=cut

#########################################################################

=head2 B<_show> - print UI element

    $ui_element->_show;

=head3 description:

Show the complete window by printing its title and all its elements.  Active
elements (basically everything not just simple C<L<Text|UI::Various::Text>>)
are numbered to allow later interaction with them.  I<The method should only
be called from C<L<_process|/_process - handle action of UI element>>!>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _show($)
{
    debug(3, __PACKAGE__, '::_show');
    my ($self) = @_;
    local $_;

    print $self->_wrap('========== ', $self->title), "\n";

    # 1st gather active children and get width of prefix:
    $self->{_active} = [];
    while ($_ = $self->child)
    {
	$_->can('_process')  and  push @{$self->{_active}}, $_;
    }
    $_ = @{$self->{_active}};
    $_ = length($_);

    # print children:
    my $pre_active = '<%' . $_ . 'd> ';
    my $pre_passive = ' ' x ($_ + 3);
    my $i = 1;
    while ($_ = $self->child)
    {
	if ($_->can('_process'))
	{   $_->_show(sprintf($pre_active, $i++));   }
	else
	{   $_->_show($pre_passive);   }
    }

    # print standard selection strings:
    print $self->_wrap(sprintf($pre_active, 0), msg('leave_window') .
		       ($self->parent->children > 1 ?
			msg('next_previous_window') : '')), "\n\n";
    print $self->_wrap('----- ', msg('enter_number_to_choose_next_step')), ': ';
}

#########################################################################

=head2 B<_process> - handle action of UI element

    $ui_element->_process;

=head3 description:

Handle the action of the UI element.  For a C<PoorTerm>'s window this means
a loop of printing the window's elements and allowing to select one of the
active ones for processing until the window is exited or destroyed.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _process($)
{
    debug(3, __PACKAGE__, '::_process');
    my ($self) = @_;
    local $_ = -1;

    my $toplevel = $self->parent->children;
    while (1)
    {
	if (defined $self->{_self_destruct})
	{   $self->_self_destruct;   return;   }
	$toplevel == $self->parent->children  or  return 0;
	$self->_show;
	$_ = <STDIN>;
	print $_;
	s/\r?\n$//;
	return $_  if  m/^[-0+]$/;
	unless ($_ =~ m/^\d+$/  and  $_ <= @{$self->{_active}})
	{   error('invalid_selection');   $_ = -1;   next;   }
	$self->{_active}->[$_-1]->_process;
    }
}

#########################################################################

=head2 B<destroy> - remove window from application

C<PoorTerm>'s concrete implementation of
L<UI::Various::Window::destroy|UI::Various::Window/destroy - remove window
from application> sets a flag for auto-destruction in C<L<_process|/_process
- handle action of UI element>>.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub destroy($)
{
    debug(2, __PACKAGE__, '::destroy');
    my ($self) = @_;
    $self->{_self_destruct} = 1;
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Window>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
