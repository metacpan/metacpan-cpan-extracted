package UI::Various::Text;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Text - general text widget of L<UI::Various>

=head1 SYNOPSIS

    use UI::Various;
    my $main = UI::Various::main();
    $main->window(UI::Various::Text->new(text => 'Hello World!'),
                  ...);
    $main->mainloop();

=head1 ABSTRACT

This module defines the general text widget of an application using
L<UI::Various>.

=head1 DESCRIPTION

Besides the common attributes inherited from C<UI::Various::widget> the
C<Text> widget knows only one additional attribute:

=head2 Attributes

=over

=cut

#########################################################################

use v5.14.0;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.03';

use UI::Various::core;
use UI::Various::widget;
BEGIN  {  require 'UI/Various/' . UI::Various::core::using() . '/Text.pm';  }

require Exporter;
our @ISA = qw(UI::Various::widget);
our @EXPORT_OK = qw();

#########################################################################

=item text [rw]

the text as string or variable reference

=cut

sub text($;$)
{
    return access('text', undef, @_);
}

#########################################################################
#
# internal constants and data:

use constant ALLOWED_PARAMETERS =>
    (UI::Various::widget::COMMON_PARAMETERS, qw(text));
use constant DEFAULT_ATTRIBUTES => (text => '');

#########################################################################
#########################################################################

=back

=head1 METHODS

Besides the accessors (attributes) described above and by
L<UI::Various::widget|UI::Various::widget/Attributes> and the methods
inherited from L<UI::Various::widget|UI::Various::widget/METHODS> only the
constructor is provided by the abstract C<Text> class itself:

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
    my $self = construct({ DEFAULT_ATTRIBUTES },
			 '^(?:' . join('|', ALLOWED_PARAMETERS) . ')$',
			 @_);
    bless $self, UI::Various::core::ui() . '::Text';
    return $self;
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
