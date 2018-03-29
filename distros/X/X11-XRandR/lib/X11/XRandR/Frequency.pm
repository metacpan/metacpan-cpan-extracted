package X11::XRandR::Frequency;

# ABSTRACT: A Frequency value

use Types::Standard qw[ Enum ];
use Types::Common::Numeric qw[ PositiveNum ];

use Moo;
use namespace::clean;
use MooX::StrictConstructor;

our $VERSION = '0.01';

#pod =attr value
#pod
#pod The value
#pod
#pod =cut


use overload '""' => \&to_string;
has value         => (
    is       => 'ro',
    isa      => PositiveNum,
    required => 1,
);

#pod =attr unit
#pod
#pod The unit. May be C<MHz>, C<KHz>, C<Hz>.
#pod
#pod =cut

has unit => (
    is       => 'ro',
    isa      => Enum [qw( MHz KHz Hz )],
    required => 1,
);

#pod =method to_Hz
#pod
#pod Convert the value to Hz.
#pod
#pod =cut

my %to_Hz = (
    MHz => 1e6,
    KHz => 1e3,
    Hz  => 1,
);

sub to_Hz {

    my $self = shift;

    return $self->value * $to_Hz{ $self->unit };
}


#pod =method to_string
#pod
#pod Return a string rendition of the object just as B<xrandr> would.
#pod
#pod =cut

sub to_string {
    sprintf( "%f%s", $_[0]->value, $_[0]->unit );
}

1;

#
# This file is part of X11-XRandR
#
# This software is Copyright (c) 2018 by Diab Jerius.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=head1 NAME

X11::XRandR::Frequency - A Frequency value

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 value

The value

=head2 unit

The unit. May be C<MHz>, C<KHz>, C<Hz>.

=head1 METHODS

=head2 to_Hz

Convert the value to Hz.

=head2 to_string

Return a string rendition of the object just as B<xrandr> would.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=X11-XRandR> or by email
to L<bug-X11-XRandR@rt.cpan.org|mailto:bug-X11-XRandR@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/x11-xrandr>
and may be cloned from L<git://github.com/djerius/x11-xrandr.git>

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<X11::XRandR|X11::XRandR>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Diab Jerius.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
