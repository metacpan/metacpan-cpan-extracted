use strict;
use warnings;

package Tiny::OpenSSL::CertificateSigningRequest;

# ABSTRACT: Certificate Signing Request object.
our $VERSION = '0.1.3'; # VERSION

use Carp;
use Moo;
use Types::Standard qw( InstanceOf );
use Path::Tiny;
use Capture::Tiny qw( :all );
use Tiny::OpenSSL::Config qw($CONFIG);

with 'Tiny::OpenSSL::Role::Entity';

has subject => (
    is       => 'rw',
    isa      => InstanceOf ['Tiny::OpenSSL::Subject'],
    required => 1
);

has key =>
    ( is => 'rw', isa => InstanceOf ['Tiny::OpenSSL::Key'], required => 1 );

sub create {
    my $self = shift;

    my @args = @{ $CONFIG->{req}{opts} };

    push @args, '-new';
    push @args, '-subj', $self->subject->dn;
    push @args, '-key', $self->key->file;

    my $pass_file;

    if ( $self->key->password ) {
        $pass_file = Path::Tiny->tempfile;
        $pass_file->spew( $self->key->password );
        push( @args, '-passin', sprintf( 'file:%s', $pass_file ) );
    }

    push @args, '-out', $self->file;

    my ( $stdout, $stderr, $exit ) = capture {
        system( $CONFIG->{openssl}, @args );
    };

    if ( $exit != 0 ) {
        croak( sprintf( 'cannot create csr: %s', $stderr ) );
    }

    $self->ascii( $self->file->slurp );

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tiny::OpenSSL::CertificateSigningRequest - Certificate Signing Request object.

=head1 VERSION

version 0.1.3

=head1 METHODS

=head2 subject

A Tiny::OpenSSL::Subject object.

=head2 key

A Tiny::OpenSSL::Key object.

=head2 create

Create a certificate signing request.

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
