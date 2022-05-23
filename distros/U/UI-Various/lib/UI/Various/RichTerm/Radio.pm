package UI::Various::RichTerm::Radio;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::RichTerm::Radio - concrete implementation of L<UI::Various::Radio>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Radio;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Radio> using
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

our $VERSION = '0.22';

use UI::Various::core;
use UI::Various::Radio;
use UI::Various::RichTerm::base qw(%D);

require Exporter;
our @ISA = qw(UI::Various::Radio UI::Various::RichTerm::base);
our @EXPORT_OK = qw();

#########################################################################
#########################################################################

=head1 METHODS

=cut

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
    my ($w, $h) = (0, 0);
    local $_;

    foreach (0..$#{$self->{_button_values}})
    {
	my ($_w, $_h) =
	    $self->_size($self->{_button_values}[$_], $content_width);
	$w > $_w  or  $w = $_w;
	$h += $_h;
    }
    return ($w, $h);
}

#########################################################################

=head2 B<_show> - return formatted UI element

    $string = $ui_element->_show($prefix, $width, $height);

=head3 example:

    my ($w, $h) = $_->_prepare($content_width);
    ...
    $_->_show('(1) ', $w, $h);

=head3 parameters:

    $prefix             text in front of first line
    $width              the width returned by _prepare above
    $height             the height returned by _prepare above

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
    my ($self, $prefix, $width, $height) = @_;
    my $blank = ' ' x length($prefix);
    # Note that the accessor automatically dereferences the SCALAR here:
    my $var = $self->var;
    defined $var  or  $var = '$ ^ }!\\"{]}[%]'; # magic invalid string
    my @text = ();
    foreach my $i (0..$#{$self->{_button_keys}})
    {
	local $_ = ($i == 0 ? $prefix : $blank) . $D{RL};
	$_ .= ($var  eq  $self->{_button_keys}[$i] ? 'o' : ' ') . $D{RR} . ' ';
	push @text, $self->_format($_, '', '', $self->{_button_values}[$i],
				   '', '', $width, 0);
    }
    return $self->_format('', '', '', \@text, '', '', $width, $height);
}

#########################################################################

=head2 B<_process> - handle action of UI element

    $ui_element->_process;

=head3 description:

Handle the action of the UI element (aka select one of the radio buttons).

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _process($)
{
    my ($self) = @_;

    my $max = @{$self->{_button_keys}};
    my $prefix = '<%' . length($max) . 'd> ';
    my $blank = ' ' x (length($max) + 3);
    my $prompt = '';
    my $selected = '';
    # Note that the accessor automatically dereferences the SCALAR here:
    my $var = $self->var;
    defined $var  or  $var = '$ ^ }!\\"{]}[%]'; # magic invalid string
    $Text::Wrap::columns = $self->width;
    foreach my $i (0..$#{$self->{_button_keys}})
    {
	$prompt .= Text::Wrap::wrap(sprintf($prefix, $i + 1), $blank,
				    $self->{_button_values}[$i]);
	$prompt .= "\n";
	$var eq $self->{_button_keys}[$i]  and  $selected = $i + 1;
    }
    $prompt .= Text::Wrap::wrap('', '', msg('enter_selection') . ' (' .
				sprintf(msg('_1_to_cancel'), 0) . '): ');
    my $re_valid = '^(?:' . join('|', 0..$max) . ')$';
    local $_ = $self->top->readline($prompt, $re_valid, $selected);
    0 < $_  and  ${$self->{var}} = $self->{_button_keys}[$_ - 1];
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Radio>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
