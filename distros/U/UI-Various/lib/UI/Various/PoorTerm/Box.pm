package UI::Various::PoorTerm::Box;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::PoorTerm::Box - concrete implementation of L<UI::Various::Box>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Box;

=head1 ABSTRACT

This module is the specific minimal fallback implementation of
L<UI::Various::Box>.  It manages and hides everything specific to the last
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

our $VERSION = '0.37';

use UI::Various::core;
use UI::Various::Box;
use UI::Various::PoorTerm::container;

require Exporter;
our @ISA = qw(UI::Various::Box UI::Various::PoorTerm::container);
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

Show the complete box by printing a separator (blank line unless the border
should be visible) and its indented content.  If the box is not indented,
its active elements are numbered to allow later interaction with them.
I<The method should only be called from C<L<_process|/_process - handle
action of UI element>> or a I::Various::PoorTerm container element!>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _show($$)
{
    my ($self, $prefix) = @_;
    defined $prefix  or  $prefix = '';
    my $blank = ' ' x length($prefix);
    local $_;

    # The number of '_show' parents' calls is the indention level:
    my $level = 0;
    $level++ while (caller($level + 1))[3] =~ m/::_show$/;
    my $indent = $level <= 1 ? '' : '    ';
    my $border = $self->border ? '----------' : '';

    $prefix ne ''  and  print $indent, $prefix, $border, "\n";

    # 1st gather active children and get width of prefix:
    $self->{_active} = [];
    while ($_ = $self->child)
    {
	$_->can('_process')  and  push @{$self->{_active}}, $_;
    }
    my $active = @{$self->{_active}};
    $_ = length($active);

    # print children:
    my $pre_active = '<%' . $_ . 'd> ';
    my $pre_passive = ' ' x ($_ + 3);
    my $i = 1;
    foreach my $row (0..($self->rows - 1))
    {
	foreach my $column (0..($self->columns - 1))
	{
	    $_ = $self->field($row, $column);
	    next unless defined $_;
	    my $pre_child = $indent;
	    if ($prefix =~ m/[^ ]/)
	    {
		if ($active == 1  and  $_->can('_process'))
		{   $pre_child .= '<*> ';   }
		else
		{   $pre_child .= $blank;   }
	    }
	    elsif ($prefix eq '')
	    {
		$pre_child .= $_->can('_process')
		    ? sprintf($pre_active, $i++) : $pre_passive;
	    }
	    else
	    {   $pre_child .= $blank;   }
	    $_->_show($pre_child);
	}
    }

    # finish as child or master of selection:
    if ($prefix ne '')
    {
	print $indent, $blank, $border, "\n";
    }
    else
    {
	# print standard selection strings:
	print $self->_wrap(sprintf($pre_active, 0), msg('leave_box')), "\n\n";
	print $self->_wrap('----- ',
			   msg('enter_number_to_choose_next_step')), ': ';
    }
}

#########################################################################

=head2 B<_process> - handle action of UI element

    $ui_element->_process;

=head3 description:

Handle the action of the UI element.  For a C<PoorTerm>'s box this means: If
the box has no active element, just return.  If it has exactly one active
element, the active element is processed directly.  Otherwise the method
iterates through a loop of printing the box's elements and allowing to
select one of the active ones for processing until the box is exited.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _process($)
{
    debug(3, __PACKAGE__, '::_process');
    my ($self) = @_;

    my $active = @{$self->{_active}};
    $active == 1  and  $self->{_active}->[0]->_process;
    $active <= 1  and  return 0;

    while (1)
    {
	if ($self->_toplevel  and  defined $self->_toplevel->{_self_destruct})
	{   return undef;   }
	$self->_show;
	local $_ = <STDIN>;
	print $_;
	s/\r?\n$//;
	return $_  if  m/^0$/;
	unless ($_ =~ m/^\d+$/  and  $_ <= @{$self->{_active}})
	{   error('invalid_selection');   next;   }
	$self->{_active}->[$_-1]->_process;
    }
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Box>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
