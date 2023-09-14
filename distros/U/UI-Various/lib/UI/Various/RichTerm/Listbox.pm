package UI::Various::RichTerm::Listbox;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::RichTerm::Listbox - concrete implementation of L<UI::Various::Listbox>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Listbox;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Listbox> using
the rich terminal UI.

=head1 DESCRIPTION

The documentation of this module is only intended for developers of the
package itself.

Note that RichTerm's listboxes can only page forward

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
use UI::Various::RichTerm::base qw(%D);

require Exporter;
our @ISA = qw(UI::Various::Listbox UI::Various::RichTerm::base);
our @EXPORT_OK = qw();

#########################################################################
#########################################################################

=head1 _Entry - helper class

C<_Entry> is an internal helper class used to access the currently
selectable entries of the listbox.

=cut

package UI::Various::RichTerm::Listbox::_Entry
{
    sub new($$)
    {
	my $self = { listbox => $_[1], index => $_[2] };
	bless $self, 'UI::Various::RichTerm::Listbox::_Entry';
    }
    sub _process($)
    {
	my ($self) = @_;
	$self->{listbox}->_process($self->{index});
    }
};

#########################################################################
#########################################################################

=head1 METHODS

=cut

#########################################################################

=head2 B<_additional_active> - return helper array of active entries

    my @active = $ui_element->_additional_active;

=head3 description:

Return a list of C<L<_Entry helper class|/_Entry - helper class>> elements
for each visible line of the listbox (the listbox's height in total).

Note that those are in addition to the one of the listbox itself, which is
used to page forward.

Also note that empty entries (when the height is greater than the amount of
visible listbox entries) are silently ignored during processing in
C<L<_process|/_process - handle action of UI element>>

=head3 returns:

helper array of active entries

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _additional_active($)
{
    my ($self) = @_;
    my @active = ();
    if ($self->selection > 0)
    {
	local $_;
	foreach (0 .. $self->height - 1)
	{
	    push @active,
		UI::Various::RichTerm::Listbox::_Entry->new($self, $_);
	}
	$self->{_active} = \@active;
    }
    return @active;
}

#########################################################################

=head2 B<_prepare> - prepare UI element

    ($width, $height) = $ui_element->_prepare($content_width);

=head3 example:

    my ($w, $h) = $_->_prepare($content_width);
    $width < $w  and  $width = $w;
    $height += $h;

=head3 parameters:

    $content_width      preferred width of content

=head3 description:

Prepare output of the UI element by determining and returning the space it
wants or needs.  I<The method should only be called from
C<UI::Various::RichTerm> container elements!>

=head3 returns:

width and height the UI element will require or need when printed

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _prepare($$)
{
    my ($self, $content_width) = @_;
    local $_ = @{$self->{texts}};
    my $w = 2 + 3 * length($_);	# minimum width for I-K/N title

    foreach (@{$self->{texts}})
    {
	my $_w = length($_);
	$w >= $_w  or  $w = $_w;
    }
    $w <= $self->width  or  $w = $self->width;
    return ($w, $self->height + 1);
}

#########################################################################

=head2 B<_show> - return formatted UI element

    $string = $ui_element->_show($prefix, $width, $height, $pre_active);

=head3 example:

    my ($w, $h) = $_->_prepare($content_width);
    ...
    $_->_show('<1> ', $w, $h, $pre_active);

=head3 parameters:

    $prefix             text in front of first line
    $width              the width returned by _prepare above
    $height             the height returned by _prepare above
    $pre_active         format string for prefixes

=head3 description:

Return the formatted (rectangular) text box of the UI element.  Its height
will be exactly as specified, unless there hasn't been enough space.  The
weight is similarly as specified plus the width needed for the prefix.
I<The method should only be called from UI::Various::RichTerm container
elements!>

=head3 returns:

the rectangular text box for UI element

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _show($$$$)
{
    my ($self, $prefix, $width, $height, $pre_active) = @_;
    my $l_prefix = length($prefix);
    my $blank = ' ' x $l_prefix;
    my ($i, $h, $selection) = ($self->first, $self->height, $self->selection);
    my @text = ();
    my $entries = @{$self->texts};
    if ($entries)
    {
	my $last = $i + $h;
	$last <= $entries  or  $last = $entries;
	$prefix =~ s/ $/+/;
	push @text, $prefix . ($i + 1) . '-' . $last . '/' . $entries;
    }
    else
    {   push @text, $blank. "0/0\n";   }
    local $_ = 0;
    while ($_ < $h)
    {
	if (0 <= $i  &&  $i < $entries)
	{
	    my $text = $self->{texts}[$i];
	    length($text) <= $width  or  $text = substr($text, 0, $width);
	    if (0 == $selection)
	    {   $text = $blank . $text;   }
	    else
	    {
		if ($self->{_selected}[$i] ne ' ')
		{   $text = $D{SL1} . $text . $D{SL0};   }
		$prefix = $blank;
		my $tl = $self->_toplevel;
		if ($tl)
		{
		    my $active = $self->{_active}[$_];
		    my $active_index = $tl->{_active_index}{$active};
		    $prefix = sprintf($pre_active, $active_index);
		}
		$text = $prefix . $text;
	    }
	    #####  selected entries become BOLD or INVERTED:
	    push @text, $text;
	    $i++;
	}
	else
	{   push @text, ' ';   }
	$_++;
    }
    $width += $l_prefix;	# input width doesn't contain prefix (text does!)
    return $self->_format('', '', '', \@text, '', '', $width, $height);
}

#########################################################################

=head2 B<_process> - handle action of UI element

    $ui_element->_process;

=head3 description:

Handle the action of the UI element (aka select one of the radio buttons).

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _process($$)
{
    my ($self, $index) = @_;

    if (defined $index)
    {
	local $_ = $self->{first} + $index;
	$_ < @{$self->texts}  or  return;
	if (1 == $self->selection)
	{
	    foreach my $i (0..$#{$self->texts})
	    {
		$self->{_selected}[$i] =
		    $i != $_ ? ' ' : $self->{_selected}[$i] eq ' ' ? '*' : ' ';
	    }
	}
	else
	{
	    $self->{_selected}[$_] = $self->{_selected}[$_] eq ' ' ? '*' : ' ';
	}
	defined $self->{on_select}  and  &{$self->{on_select}};
    }
    else
    {
	my $h = $self->height;
	my $entries = @{$self->texts};
	$self->{first} += $h;
	if ($self->{first} >= $entries)
	{
	    $self->{first} = 0;
	}
	elsif ($self->{first} + $h > $entries)
	{
	    $self->{first} = $entries - $h;
	}
    }
}

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
