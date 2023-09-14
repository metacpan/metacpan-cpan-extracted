package UI::Various::PoorTerm::Radio;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::PoorTerm::Radio - concrete implementation of L<UI::Various::Radio>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Radio;

=head1 ABSTRACT

This module is the specific minimal fallback implementation of
L<UI::Various::Radio>.  It manages and hides everything specific to the last
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
use UI::Various::Radio;
use UI::Various::PoorTerm::base;

require Exporter;
our @ISA = qw(UI::Various::Radio UI::Various::PoorTerm::base);
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
    my $var = $self->var;
    defined $var  or  $var = '$ ^ }!\\"{]}[%]'; # magic invalid string
    foreach my $i (0..$#{$self->{_button_keys}})
    {
	local $_ = ($i == 0 ? $prefix : $blank) . '(';
	# Note that the accessors automatically dereference the SCALARs here:
	$_ .= ($var  eq  $self->{_button_keys}[$i] ? 'o' : ' ') . ') ';
	print $self->_wrap($_, $self->{_button_values}[$i]), "\n";
    }
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
    my $prompt = '';
    foreach my $i (0..$#{$self->{_button_keys}})
    {
	$prompt .= $self->_wrap(sprintf($prefix, $i + 1),
				$self->{_button_values}[$i]);
	$prompt .= "\n";
    }
    $prompt .= $self->_wrap('',
			    msg('enter_selection') .
			    ' (' . sprintf(msg('_1_to_cancel'), 0) . '): ');

    local $_ = -1;
    while ($_ < 0)
    {
	print $prompt;
	$_ = <STDIN>;
	print $_;
	s/\r?\n$//;
	unless (m/^\d+$/  and  $_ <= $max)
	{   error('invalid_selection');   $_ = -1;   next;   }
	0 < $_  and  ${$self->{var}} = $self->{_button_keys}[$_ - 1];
    }
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
