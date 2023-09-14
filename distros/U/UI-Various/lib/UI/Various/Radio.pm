package UI::Various::Radio;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Radio - general radio button widget of L<UI::Various>

=head1 SYNOPSIS

    use UI::Various;
    my $main = UI::Various::main();
    my $variable = 0;
    $main->window(...
                  UI::Various::Radio->new(buttons => [1 => 'One',
                                                      2 => 'Two',
                                                      3 => 'Three']),
                  ...);
    $main->mainloop();

=head1 ABSTRACT

This module defines the general radio button widget of an application using
L<UI::Various>. The radio buttons are vertically aligned.

Note that the limitation to the vertical orientation comes from
L<Curses::UI::Radiobuttonbox>.

=head1 DESCRIPTION

Besides the common attributes inherited from C<UI::Various::widget> the
C<Radio> widget knows only two additional attributes:

Note that the possible values for the variable are C<0> or C<1>, which will
be changed according Perl's standard true/false conversions.

=head2 Attributes

=over

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.42';

use UI::Various::core;
use UI::Various::widget;
BEGIN  {  require 'UI/Various/' . UI::Various::core::using() . '/Radio.pm';  }

require Exporter;
our @ISA = qw(UI::Various::widget);
our @EXPORT_OK = qw();

#########################################################################

=item buttons [rw, fixed]

an ARRAY with pairs of key values and corresponding displayed texts of the
radio buttons, e.g.:

    [ 1 => 'red', 2 => 'green', 3 => 'blue' ]

(looks like a HASH, but is technically an ARRAY as its sequence is important)

=cut

sub buttons($;$)
{
    local $_ =
	access
	('buttons',
	 sub{
	     unless (ref($_) eq 'ARRAY')
	     {
		 error('_1_attribute_must_be_a_2_reference', 'buttons', 'ARRAY');
		 return undef;
	     }
	     if (0 == @{$_})
	     {
		 error('_1_may_not_be_empty', 'buttons');
		 return undef;
	     }
	     unless (0 == @{$_} % 2)
	     {
		 error('odd_number_of_parameters_in_initialisation_list_of__1',
		       'buttons');
		 return undef;
	     }
	     my ($self) = @_;
	     my @keys = ();
	     my @values = ();
	     foreach my $i (0..$#{$_})
	     {
		 if (0 == $i % 2)
		 {   push @keys, $_->[$i];   }
		 else
		 {   push @values, $_->[$i];   }
	     }
	     my %hash = @$_;
	     $self->{_button_hash} = \%hash;
	     $self->{_button_keys} = \@keys;
	     $self->{_button_values} = \@values;
	 },
	 @_);
    _init_var(@_);
    return $_;
}

=item var [rw, recommended]

a variable reference for the radio buttons

The variable will be set to one of the key values of C<L<buttons|/buttons rw
fixed>> when it is selected.  Note that if it's initial value is defined to
something not being an existing key value of that ARRAY, it will be set to
C<undef>.

=cut

sub var($;$)
{
    local $_ = access_varref('var', @_);
    _init_var(@_);
    return $_;
}

# need special initialisation function as initialisation sequence is
# undefined:
sub _init_var($;@)
{
    my ($self) = @_;
    return unless ($self->isa(__PACKAGE__)  and
		   defined $self->{buttons}  and
		   defined $self->{var}  and
		   defined ${$self->{var}});
    # direct access to avoid recursion:
    defined $self->{_button_hash}{${$self->{var}}}  or  ${$self->{var}} = undef;
}

#########################################################################
#
# internal constants and data:

use constant ALLOWED_PARAMETERS =>
    (UI::Various::widget::COMMON_PARAMETERS, qw(buttons var));
use constant DEFAULT_ATTRIBUTES => (var => dummy_varref());

#########################################################################
#########################################################################

=back

=head1 METHODS

Besides the accessors (attributes) described above and by
L<UI::Various::widget|UI::Various::widget/Attributes> and the methods
inherited from L<UI::Various::widget|UI::Various::widget/METHODS> only the
constructor is provided by the C<Radio> class itself:

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
    unless (defined $_->{buttons})
    {
	error('mandatory_parameter__1_is_missing', 'buttons');
	return undef;
    }
    return $_;
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
