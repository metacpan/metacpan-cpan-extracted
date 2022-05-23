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

=head2 Attributes

=over

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.22';

use UI::Various::core;
use UI::Various::widget;
BEGIN  {  require 'UI/Various/' . UI::Various::core::using() . '/Check.pm';  }

require Exporter;
our @ISA = qw(UI::Various::widget);
our @EXPORT_OK = qw();

#########################################################################

=item text [rw, recommended]

the text as string or variable reference

Note that the reference will be dereferenced during initialisation.  Later
changes will be ignored, as not all possible UIs would support that change.

=cut

sub text($;$)
{
    return access('text', undef, @_);
}

=item var [rw, recommended]

a variable reference for the checkbox

The variable will switched on (C<1>) and off (C<0>) by the checkbox.

Note that the initial values for the variable will be changed to C<0> or
C<1> according Perl's standard true/false conversions.

=cut

sub var($;$)
{
    local $_ = access_varref('var', @_);
    defined $_[1]  and  ref($_[1]) eq 'SCALAR'  and  ${$_[1]} = ${$_[1]} ? 1 : 0;
    return $_;
}

#########################################################################
#
# internal constants and data:

use constant ALLOWED_PARAMETERS =>
    (UI::Various::widget::COMMON_PARAMETERS, qw(text var));
use constant DEFAULT_ATTRIBUTES => (text => '', var => dummy_varref());

#########################################################################
#########################################################################

=back

=head1 METHODS

Besides the accessors (attributes) described above and by
L<UI::Various::widget|UI::Various::widget/Attributes> and the methods
inherited from L<UI::Various::widget|UI::Various::widget/METHODS> only the
constructor is provided by the C<Check> class itself:

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

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
