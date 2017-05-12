use strict;
use warnings;

package Tiny::OpenSSL::Subject;

# ABSTRACT: X509 Subject object.
our $VERSION = '0.1.3'; # VERSION

use Moo;
use Types::Standard qw( Str InstanceOf Int );
use Tiny::OpenSSL::Config qw($CONFIG);

has [ keys %{ $CONFIG->{san} } ] => ( is => 'rw', isa => Str );

sub dn {
    my $self = shift;

    my @subject;

    my @methods =
        qw( country state locality organization organizational_unit commonname );

    for my $method (@methods) {

        if ( $self->$method ) {
            push @subject,
                sprintf( '%s=%s', $CONFIG->{san}{$method}, $self->$method );
        }
    }

    return sprintf( '/%s', join( '/', @subject ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tiny::OpenSSL::Subject - X509 Subject object.

=head1 VERSION

version 0.1.3

=head1 METHODS

=head2 dn

Returns the X509 subject string.

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
