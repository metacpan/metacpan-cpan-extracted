package UI::Various::RichTerm::Dialog;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::RichTerm::Dialog - concrete implementation of L<UI::Various::Dialog>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Dialog;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Dialog> using
the rich terminal UI.

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

our $VERSION = '0.25';

use UI::Various::core;
use UI::Various::Dialog;
use UI::Various::RichTerm::container;
use UI::Various::RichTerm::base qw(%D);

require Exporter;
our @ISA = qw(UI::Various::Dialog UI::Various::RichTerm::container);
our @EXPORT_OK = qw();

#########################################################################
#########################################################################

=head1 METHODS

=cut

#########################################################################

=head2 B<_show> - print UI element

    $ui_element->_show;

=head3 description:

Show the complete dialogue by printing its title and its elements.  Active
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

    # 1. gather active children:
    my @active = $self->_all_active;
    $self->{_active} = [ @active ];
    my %reverse = ();
    $reverse{$active[$_]} = $_ + 1  foreach  0..$#active;
    $self->{_active_index} = \%reverse;

    # 2. determine prefixes (format string plus empty one), if applicable:
    my ($pre_active, $pre_passive) = ('', '');
    my $active = @active;
    my $pre_len = 0;
    if (0 < $active)
    {
	$pre_len = length($active);
	$pre_active = '<%' . $pre_len . 'd> ';
	$pre_len += 3;
	$pre_passive = ' ' x $pre_len;
    }
    my $own_active = 0;
    while ($_ = $self->child)
    {   $own_active++ if $_->can('_process');   }

    # 3. determine space requirements of children:
    my $my_width = $self->{width};		# Don't use inheritance here!
    my $content_width = defined $my_width ? $my_width : $self->max_width;
    $content_width -= (2 + $pre_len);		# - 2 chars border decoration
    defined $my_width  or  $my_width = 1;
    my $title_len = length($self->title) + 3;	# + 1 decoration + 2 blanks
    $my_width >= $title_len  or  $my_width = $title_len + 2;
    $my_width -= (2 + $pre_len);		# - 2 chars border decoration
    $self->{_space} = [];
    $self->{_total_height} = 2;
    while ($_ = $self->child)
    {
	my ($w, $h) = $_->_prepare($content_width, $pre_len);
	$my_width >= $w  or  $my_width = $w;
	$self->{_total_height} += $h;
	push @{$self->{_space}}, [$w, $h];
    }

    # 4. concatenate text boxes of all children:
    my $i = 0;
    my @output = ();
    while ($_ = $self->child)
    {
	my ($w, $h) = @{$self->{_space}[$i++]};
	my $prefix = '';
	if (0 < $own_active)
	{
	    $prefix = $pre_passive;
	    if ($_->can('_process'))
	    {   $prefix = sprintf($pre_active, $self->{_active_index}{$_});   }
	}
	push @output, split(m/\n/, $_->_show($prefix, $w, $h, $pre_active));
    }

    # 5. print full dialogue (text box plus frame):
    $my_width += $pre_len if $own_active;
    my $title = $self->title ? ' ' . $self->title . ' ' : $D{W8} x 2;
    print $D{W7}, $D{W8}, $title;
    $_ = $my_width - $title_len;
    print $D{W8} x ($_ > 3 ? $_ - 3 : $_), ($_ > 3 ? '<0>' : '');
    print $D{W9}, "\n";
    print($self->_format('', $D{W4}, '', \@output, '', $D{W6}, $my_width, 0),
	  "\n");
    my $h = $self->height;
    defined $h  or  $h = 0;
    $h < $self->max_height  or  $h = $self->max_height;
    while ($h-- > $self->{_total_height})
    {   print $D{W4}, ' ' x $my_width, $D{W6}, "\n";   }
    print $D{W1}, $D{W2} x $my_width, $D{W3}, "\n";
}

#########################################################################

=head2 B<_process> - handle action of UI element

    $return_code = $ui_element->_process;

=head3 description:

Handle the action of the UI element.  For a C<RichTerm>'s dialogue this means
a loop of printing the dialogue's elements and allowing to select one of the
active ones for processing until the dialogue is exited, changed or destroyed.

=head3 returns:

C<0> for simple exit and C<undef> after destruction

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _process($)
{
    debug(3, __PACKAGE__, '::_process');
    my ($self) = @_;

    my $prompt = msg('enter_selection') . ': ';
    while (1)
    {
	if (defined $self->{_self_destruct})
	{   $self->_self_destruct;   return undef;   }
	$self->_show;
	local $_ = undef;
	until ($_)		# loop until selection of active child
	{
	    $_ = $self->top->readline($prompt, qr/^(\d+)$/s);
	    if ($_ eq '0')
	    {   $self->destroy;   return 0;   }
	    if ($_ > @{$self->{_active}})
	    {   error('invalid_selection');   redo;   }
	}
	$self->{_active}->[$_-1]->_process;
    }
}

#########################################################################

=head2 B<destroy> - remove dialogue from application

C<RichTerm>'s concrete implementation of
L<UI::Various::Dialog::destroy|UI::Various::Dialog/destroy - remove dialogue
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

L<UI::Various>, L<UI::Various::Dialog>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
