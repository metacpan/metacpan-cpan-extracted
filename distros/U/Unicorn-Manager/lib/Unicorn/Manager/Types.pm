package Unicorn::Manager::Types;

use Moo;
use 5.010;
use Try::Tiny;
use Socket;
use Net::Interface;

sub hashref {
    return sub {
        die "Failed type constraint. Should be a HashRef but is a " . ref( $_[0] )
            if ref( $_[0] ) ne 'HASH';
        }
}

sub local_address {
    return sub {
        my $param = shift;

        my @addresses = map {
            map { Net::Interface::inet_ntoa($_) } $_->address;
        } Net::Interface->interfaces;

        if ( $param =~ /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/ ) {
            return 1 if grep { $_ eq $param } @addresses;
            die "Can not listen on $param. No interface with this address.";
        }
        else {
            if ( my $packed = gethostbyname $param ) {
                my $address = Socket::inet_ntoa $packed;
                return 1 if grep { $_ eq $address } @addresses;
            }
            die "Can not listen on $param. Hostname not resolvable.";
        }

        }
}

1;

__END__

=head1 NAME

Unicorn::Manager::Types - Types to be used by Unicorn

=head1 VERSION

Version 0.006009

=head1 SYNOPSIS

Types used within Unicorn::Manager classes.

=head1 TYPES

=head2 hashref

Attribute has to be a reference to a hash.

=head2 local_address

Address or hostname of a local interface.

=head1 AUTHOR

Mugen Kenichi, C<< <mugen.kenichi at uninets.eu> >>

=head1 BUGS

Report bugs at:

=over 2

=item * Unicorn::Manager issue tracker

L<https://github.com/mugenken/Unicorn/issues>

=item * support at uninets.eu

C<< <mugen.kenichi at uninets.eu> >>

=back

=head1 SUPPORT

=over 2

=item * Technical support

C<< <mugen.kenichi at uninets.eu> >>

=back

=cut

