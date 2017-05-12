package Unicorn::Manager::Version;

use strict;
use warnings;
use version;

sub new {
    my $class = shift;
    my $self  = {};
    return bless $self, $class;
}

sub get {
    my $self    = shift;
    my $VERSION = version->declare('0.06.09')->numify;
    return $VERSION;
}

1;

__END__

=head1 NAME

Unicorn::Manager::Version

=head1 WARNING!

This is an unstable development release not ready for production!

=head1 VERSION

Version 0.006009

=head1 SYNOPSIS

Unicorn::Manager::Version is uses to declare the Unicorn::Manager version.

=head1 METHODS

=head2 new

    my $umv = Unicorn::Manager::Version->new;

=head2 get

Used to get the current version of Unicorn::Manager

    my $version = $umv->get;

Or

    my $version = Unicorn::Manager::Version->get;

=head1 AUTHOR

Mugen Kenichi, C<< <mugen.kenichi at uninets.eu> >>

=head1 BUGS

Report bugs at:

=over 2

=item * Unicorn::Manager issue tracker

L<https://github.com/mugenken/p5-Ruby-VersionManager/issues>

=item * support at uninets.eu

C<< <mugen.kenichi at uninets.eu> >>

=back

=head1 SUPPORT

=over 2

=item * Technical support

C<< <mugen.kenichi at uninets.eu> >>

=back

=cut

