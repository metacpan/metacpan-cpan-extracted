package X11::XRandR::State;

# ABSTRACT: The XRandR state

use Pegex::Parser;
use X11::XRandR::Grammar::Verbose;
use X11::XRandR::Receiver::Verbose;

use Types::Standard -types;
use IPC::Cmd;
use Carp ();

use Moo;
use namespace::clean;
use MooX::StrictConstructor;

our $VERSION = '0.01';

#pod =attr screen
#pod
#pod An instance of L<X11::XRandR::Screen>.
#pod
#pod =cut

has screen => (
    is       => 'ro',
    isa      => InstanceOf ['X11::XRandR::Screen'],
    required => 1,
);

#pod =attr outputs
#pod
#pod An array of L<X11::XRandR::Output> objects
#pod
#pod =cut

has outputs => (
    is       => 'ro',
    isa      => ArrayRef [ InstanceOf ['X11::XRandR::Output'] ],
    required => 1,
);

#pod =method query
#pod
#pod A class method to query XRandR for its state using the C<xrandr> command.
#pod Returns an instance of L<X11::XRandR::State>.
#pod
#pod =cut

sub query {

    IPC::Cmd::can_run( 'xrandr' )
      or Carp::croak( "xrandr command is not in path\n" );

    my ( $success, $error_message, undef, $stdout_buf, undef )
      = IPC::Cmd::run(
        command => [qw ( xrandr --verbose )],
        verbose => 0
      );

    Carp::croak( "error running xrandr: $error_message\n" )
      if length $error_message;

    my $parser = Pegex::Parser->new(
        grammar  => X11::XRandR::Grammar::Verbose->new,
        receiver => X11::XRandR::Receiver::Verbose->new
    );

    $parser->parse( join( '', @$stdout_buf ) );
}

#pod =method to_string
#pod
#pod Return a string rendition of the object just as B<xrandr> would.
#pod
#pod =cut


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

X11::XRandR::State - The XRandR state

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 screen

An instance of L<X11::XRandR::Screen>.

=head2 outputs

An array of L<X11::XRandR::Output> objects

=head1 METHODS

=head2 query

A class method to query XRandR for its state using the C<xrandr> command.
Returns an instance of L<X11::XRandR::State>.

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
