package UI::Various::Optionmenu;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Optionmenu - general option-menu widget of L<UI::Various>

=head1 SYNOPSIS

    use UI::Various;
    my $main = UI::Various::main();
    my @options = (0, [1st => 1], [2nd => 2], [3rd => 3]);
    $main->window(...
                  UI::Various::Optionmenu->new(init => 2,
                                               options => \@options),
                  ...);
    $main->mainloop();

=head1 ABSTRACT

This module defines the general widget for a menu of options in an
application using L<UI::Various>.

=head1 DESCRIPTION

Besides the common attributes inherited from C<UI::Various::widget> the
C<Optionmenu> widget knows the following additional attributes:

=head2 Attributes

=over

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.40';

use UI::Various::core;
use UI::Various::widget;
BEGIN  {  require 'UI/Various/' . UI::Various::core::using() . '/Optionmenu.pm';  }

require Exporter;
our @ISA = qw(UI::Various::widget);
our @EXPORT_OK = qw();

#########################################################################

=item options [rw, fixed]

a reference to a list of option pairs / options

The list of options must be either an ARRAY of pairs (reference to an ARRAY
with two elements each) of menu entries with corresponding values or simple
scalar values, which will be mapped into the aforementioned pairs.

=cut

sub options($$)
{
    return access('options',
		  sub{
		      unless (ref($_) eq 'ARRAY')
		      {
			  error('_1_attribute_must_be_a_2_reference',
				'options', 'ARRAY');
			  return undef;
		      }
		      my $ra = $_;
		      foreach (@$ra)
		      {
			  if (ref($_) eq 'ARRAY')
			  {
			      error('invalid_pair_in__1_attribute', 'options')
				  if  @$_ < 2;
			  }
			  else
			  {   $_ = [ $_ => $_ ];   }
		      }
		      $_ = $ra;
		  },
		  @_);
}

=item init [wo]

option selected initially

The option selected initially must be specified by its value, not by the
menu entry.

=cut

sub _init($$)
{
    return set('_init', undef, @_);
}

=item on_select [rw, optional]

an optional callback called after changing the selection

The callback routine is called with the selected value (not menu entry) as
parameter.

Note that in L<Tk> the callback is also called during initialisation.

=cut

sub on_select($;$)
{
    return access('on_select',
		  sub{
		      unless (ref($_) eq 'CODE')
		      {
			  error('_1_attribute_must_be_a_2_reference',
				'on_select', 'CODE');
			  return undef;
		      }
		  },
		  @_);
}

#########################################################################
#
# internal constants and data:

use constant ALLOWED_PARAMETERS =>
    (UI::Various::widget::COMMON_PARAMETERS, qw(init options on_select));
use constant DEFAULT_ATTRIBUTES => ();

#########################################################################
#########################################################################

=back

=head1 METHODS

Besides the accessors (attributes) described above and by
L<UI::Various::widget|UI::Various::widget/Attributes> and the methods
inherited from L<UI::Various::widget|UI::Various::widget/METHODS> only the
constructor is provided by the C<Optionmenu> class itself:

=cut

#########################################################################

=head2 B<new> - constructor

see L<UI::Various::core::construct|UI::Various::core/construct - common
constructor for UI elements>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub new($;\[@$])
{
    debug(3, __PACKAGE__, '::new');
    local $_ = construct({ DEFAULT_ATTRIBUTES },
			 '^(?:' . join('|', ALLOWED_PARAMETERS) . ')$',
			 @_);
    unless (defined $_->{options})
    {
	error('mandatory_parameter__1_is_missing', 'options');
	return undef;
    }
    $_->{_selected} = undef;
    $_->{_selected_menu} = undef;	# only used in *Term
    if (defined $_->{_init})
    {
	foreach my $opt (@{$_->{options}})
	{
	    next unless $opt->[1] eq $_->{_init};
	    $_->{_selected_menu} = $opt->[0];
	    $_->{_selected} = $opt->[1];
	}
    }
    return $_;
}


#########################################################################

=head2 B<selected> - get current value of the menu of options

    $selection = $optionmenu->selected();

=head3 description:

This method returns the value (not the menu entry) of the currently selected
option (or C<undef> in nothing has been selected or initialised).

=head3 returns:

selected value   (or C<undef>)

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub selected($)
{
    my ($self) = @_;
    return $self->{_selected};
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
