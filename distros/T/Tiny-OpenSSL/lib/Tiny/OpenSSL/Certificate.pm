use strict;
use warnings;

package Tiny::OpenSSL::Certificate;

# ABSTRACT: X509 Certificate Object.
our $VERSION = '0.1.3'; # VERSION

use Moo;
use Carp;
use Types::Standard qw( InstanceOf );
use Tiny::OpenSSL::Config qw($CONFIG);
use Capture::Tiny qw( :all );

with 'Tiny::OpenSSL::Role::Entity';

has [qw(issuer subject)] =>
    ( is => 'rw', isa => InstanceOf ['Tiny::OpenSSL::Subject'] );

has key => ( is => 'rw', isa => InstanceOf ['Tiny::OpenSSL::Key'] );

sub self_sign {

    my $self = shift;
    my $csr  = shift;

    if ( !defined $csr ) {
        croak 'csr is not defined';
    }

    my @args = (
        'x509', '-req',     '-days',    $CONFIG->{ca}{days},
        '-in',  $csr->file, '-signkey', $self->key->file,
        '-out', $self->file
    );

    my $pass_file;

    if ( $csr->key->password ) {

        $pass_file = Path::Tiny->tempfile;
        $pass_file->spew( $self->key->password );

        push( @args, '-passin', sprintf( 'file:%s', $pass_file ) );

    }

    my ( $stdout, $stderr, $exit ) = capture {
        system( $CONFIG->{openssl}, @args );
    };

    if ( $exit != 0 ) {
        croak( sprintf( 'cannot sign certificate: %s', $stderr ) );
    }

    $self->issuer( $self->subject );
    $self->ascii( $self->file->slurp );

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tiny::OpenSSL::Certificate - X509 Certificate Object.

=head1 VERSION

version 0.1.3

=head1 METHODS

=head2 issuer

A Tiny::OpenSSL::Subject object for the issuer of the certificate.

=head2 subject

A Tiny::OpenSSL::Subject object for the subject of the certificate.

=head2 key

A Tiny::OpenSSL::Key object.

=head2 self_sign

Self sign certificate.

    $cert->self_sign($csr);

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
