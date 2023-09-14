package UI::Various::PoorTerm::Listbox;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::PoorTerm::Listbox - concrete implementation of L<UI::Various::Listbox>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Listbox;

=head1 ABSTRACT

This module is the specific minimal fallback implementation of
L<UI::Various::Listbox>.  It manages and hides everything specific to the last
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

our $VERSION = '0.42';

use UI::Various::core;
use UI::Various::Listbox;
use UI::Various::PoorTerm::base;

require Exporter;
our @ISA = qw(UI::Various::Listbox UI::Various::PoorTerm::base);
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

Show (print) the UI element.  I<The method should only be called from
UI::Various::PoorTerm container elements!>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _show($$)
{
    my ($self, $prefix) = @_;
    my $blank = ' ' x length($prefix);
    my ($i, $h) = ($self->first, $self->height);
    my $entries = @{$self->texts};
    if ($entries)
    {
	my $last = $i + $h;
	$last <= $entries  or  $last = $entries;
	print $prefix, '  ', $i + 1, '-', $last, '/', $entries, "\n";
    }
    else
    {   print $blank, "  0/0\n";   }
    local $_ = 0;
    my $empty = 0;
    while ($_ < $h)
    {
	if (0 <= $i  &&  $i < $entries)
	{
	    print $self->_cut($blank,
			      $self->{_selected}[$i], ' ',
			      $self->{texts}[$i]), "\n";
	    $i++;
	}
	else
	{
	    print "\n" unless $empty > 2;
	    $empty++;
	}
	$_++;
    }
}

#########################################################################

=head2 B<_process> - handle action of UI element

    $ui_element->_process;

=head3 description:

Handle the action of the UI element (aka scrolling and selection of
elements, if applicable).

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _process($)
{
    my ($self) = @_;
    my ($h, $selection) = ($self->height, $self->selection);
    my $entries = 0;
    my ($head, $prompt, $logh) = ('', '', 1);
    local $_ = $h;
    while ($_ >= 10)
    {   $logh++;   $_ /= 10;   }
    my $pre_active_base = '<%' . $logh . 'd> ';
    my $pre_active = $pre_active_base;
    my $re_selection = ($selection == 0 ? qr/(0)/ :
			$selection == 1 ? qr/(\d+)/ :
			qr/(\d+)(?:,\s*\d+)*/);
    $self->{_modified} = 1;
    $_ = '';
    while ($_ ne '0')
    {
	if (defined $self->{_modified})
	{
	    $entries = @{$self->texts};
	    $head = $entries > $h ? '<+/-> ' : '      ';
	    $pre_active = $pre_active_base;
	    my $diff = $logh + 5 - length($head);
	    $head .= ' ' x $diff if $diff > 0;
	    $prompt = msg('enter_selection');
	    $entries > $h  and  $prompt .= ' (' . msg('scrolls') . ')';
	    $prompt .= ': ';
	    delete $self->{_modified};
	}
	my $i = $self->{first};
	my $last = $i + $h;
	$last <= $entries  or  $last = $entries;
	print($head,
	      $entries ? ($i + 1 . '-' . $last . '/' . $entries) : '0/0',
	      "\n");
	$_ = 0;
	my $empty = 0;
	while ($_ < $h)
	{
	    $_++;
	    if (0 <= $i  &&  $i < $entries)
	    {
		if ($selection)
		{
		    print $self->_cut(sprintf($pre_active, $_),
				      $self->{_selected}[$i], ' ',
				      $self->{texts}[$i]), "\n";
		}
		else
		{   print $self->_cut($self->{texts}[$i]), "\n";   }
		$i++;
	    }
	    else
	    {
		print "\n" unless $empty > 2;
		$empty++;
	    }
	}
	print sprintf($pre_active, 0), '  ', msg('leave_listbox'), "\n";
	$_ = '';
	while ($_ eq '')
	{
	    print $prompt;
	    $_ = <STDIN>;
	    print $_;
	    s/\s+$//;
	    unless (($entries > $h  and  m/^[-+]$/)  or
		    (m/^$re_selection$/  and  $1 <= $h))
	    {   error('invalid_selection');   $_ = '';   next;   }
	}
	if ($_ eq '+')
	{
	    $self->{first} += $h;
	    $self->{first} + $h <= $entries  or  $self->{first} = $entries - $h;
	}
	elsif ($_ eq '-')
	{
	    $self->{first} -= $h;
	    $self->{first} >= 0  or  $self->{first} = 0;
	}
	else
	{
	    my $changes = 0;
	    if ($selection == 1)
	    {
		if ($_ > 0)
		{
		    foreach my $i (0..$#{$self->texts})
		    {
			$self->{_selected}[$i] =
			    $i != $self->{first} + $_ - 1 ? ' ' :
			    $self->{_selected}[$i] eq ' ' ? '*' : ' ';
			$changes++;
		    }
		}
	    }
	    else
	    {
		foreach (split m/,\s*/, $_)
		{
		    $_ > 0  or  next;
		    $i = $self->{first} + $_ - 1;
		    $self->{_selected}[$i] =
			$self->{_selected}[$i] eq ' ' ? '*' : ' ';
		    $changes++;
		}
	    }
	    defined $self->{on_select}  and  $changes > 0  and
		&{$self->{on_select}};
	}
    }
}

#########################################################################

=head2 B<_add> - add new element

C<PoorTerm>'s specific implementation of
L<UI::Various::Listbox::add|UI::Various::Listbox/add - add new element>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _add($@)
{   $_[0]->{_modified} = 1;   }

#########################################################################

=head2 B<_remove> - remove element

C<PoorTerm>'s specific implementation of
L<UI::Various::Listbox::remove|UI::Various::Listbox/remove - remove element>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _remove($$)
{   $_[0]->{_modified} = 1;   }

#########################################################################

=head2 B<_replace> - replace all elements

C<PoorTerm>'s specific implementation of
L<UI::Various::Listbox::replace|UI::Various::Listbox/replace - replace all
elements>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _replace($@)
{   $_[0]->{_modified} = 1;   }

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Listbox>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
