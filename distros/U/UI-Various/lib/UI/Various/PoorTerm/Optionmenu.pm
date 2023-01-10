package UI::Various::PoorTerm::Optionmenu;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::PoorTerm::Optionmenu - concrete implementation of L<UI::Various::Optionmenu>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Optionmenu;

=head1 ABSTRACT

This module is the specific minimal fallback implementation of
L<UI::Various::Optionmenu>.  It manages and hides everything specific to the
last resort UI.

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

our $VERSION = '0.38';

use UI::Various::core;
use UI::Various::Optionmenu;
use UI::Various::PoorTerm::base;

require Exporter;
our @ISA = qw(UI::Various::Optionmenu UI::Various::PoorTerm::base);
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
    local $_ = defined $self->{_selected_menu} ? $self->{_selected_menu} : '---';
    print $self->_wrap($prefix . '[ ', $_), " ]\n";
}

#########################################################################

=head2 B<_process> - handle action of UI element

    $ui_element->_process;

=head3 description:

Handle the action of the UI element (aka select an entry of the menu of
options).

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _process($)
{
    my ($self) = @_;

    my $max = @{$self->{options}};
    my $prefix = '<%' . length($max) . 'd> ';
    my $prompt = '';
    foreach my $i (0..$#{$self->{options}})
    {
	$prompt .= $self->_wrap(sprintf($prefix, $i + 1),
				$self->{options}[$i][0]);
	$prompt .= "\n";
    }
    $prompt .= $self->_wrap('',
			    msg('enter_selection') .
			    ' (' . sprintf(msg('_1_to_cancel'), 0) . '): ');
    while (1)
    {
	print $prompt;
	local $_ = <STDIN>;
	print $_;
	s/\r?\n$//;
	if (m/^\d+$/  and  $_ <= $max)
	{
	    $self->{_selected_menu} = $self->{options}[$_ - 1][0];
	    $self->{_selected}      = $self->{options}[$_ - 1][1];
	    $_ = $self->{on_select};
	    defined $_  and  &$_($self->{_selected});
	    return;
	}
	error('invalid_selection');
    }
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Optionmenu>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
