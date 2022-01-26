package UI::Various::Check;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Check - general checkbox widget of L<UI::Various>

=head1 SYNOPSIS

    use UI::Various;
    my $main = UI::Various::main();
    my $variable = 0;
    $main->window(...
                  UI::Various::Check->new(text => 'special mode',
                                          var => \$variable),
                  ...);
    $main->mainloop();

=head1 ABSTRACT

This module defines the general checkbox widget of an application using
L<UI::Various>.

=head1 DESCRIPTION

Besides the common attributes inherited from C<UI::Various::widget> the
C<Check> widget knows only two additional attributes:

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

our $VERSION = '0.15';

use UI::Various::core;
use UI::Various::widget;
BEGIN  {  require 'UI/Various/' . UI::Various::core::using() . '/Check.pm';  }

require Exporter;
our @ISA = qw(UI::Various::widget);
our @EXPORT_OK = qw();

#########################################################################

=item text [rw]

the text as string or variable reference

Note that the reference will dereferenced during initialisation.  Later
changes will be ignored, as not all possible UIs would support that change.

=cut

sub text($;$)
{
    return access('text', undef, @_);
}

=item var [rw]

a variable reference for the checkbox

The variable will switched on (C<1>) and off (C<0>) by the checkbox.

=cut

sub var($;$)
{
    defined $_[1]  or  return get('var', @_);
    # explicit check for SCALAR reference when used as setter (needed here
    # as SCALAR references are treated special in set/access):
    unless (ref($_[1]) eq 'SCALAR')
    {
	error('_1_attribute_must_be_a_2_reference',
	      'var', 'SCALAR');
	return undef;
    }
    ${$_[1]} = ${$_[1]} ? 1 : 0;
    return set('var', undef, @_);
}

#########################################################################
#
# internal constants and data:

use constant ALLOWED_PARAMETERS =>
    (UI::Various::widget::COMMON_PARAMETERS, qw(text var));
use constant DEFAULT_ATTRIBUTES =>
    (text => '', var => UI::Various::core::dummy_varref());

#########################################################################
#########################################################################

=back

=head1 METHODS

Besides the accessors (attributes) described above and by
L<UI::Various::widget|UI::Various::widget/Attributes> and the methods
inherited from L<UI::Various::widget|UI::Various::widget/METHODS> only the
constructor is provided by the abstract C<Check> class itself:

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
    return construct({ DEFAULT_ATTRIBUTES },
		     '^(?:' . join('|', ALLOWED_PARAMETERS) . ')$',
		     @_);
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

Thomas Dorner E<lt>dorner@cpan.orgE<gt>

=cut
