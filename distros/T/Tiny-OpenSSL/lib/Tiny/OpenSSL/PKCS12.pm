use strict;
use warnings;

package Tiny::OpenSSL::PKCS12;

# ABSTRACT: Tiny::OpenSSL::PKCS12 Object
our $VERSION = '0.1.3'; # VERSION

use Moo;
use Carp;
use Types::Standard qw( Str InstanceOf );
use Capture::Tiny qw( :all );
use Tiny::OpenSSL::Config qw($CONFIG);

with 'Tiny::OpenSSL::Role::Entity';

has certificate => (
    is       => 'rw',
    isa      => InstanceOf ['Tiny::OpenSSL::Certificate'],
    required => 1
);

has key => (
    is       => 'rw',
    isa      => InstanceOf ['Tiny::OpenSSL::Key'],
    required => 1
);

has identity => (
    is       => 'rw',
    isa      => Str,
    required => 1
);

has passphrase => (
    is       => 'rw',
    isa      => Str,
    required => 1
);


sub create {
    my $self = shift;

    my $pass_file = Path::Tiny->tempfile;
    $pass_file->spew( $self->passphrase );

    my @args = (
        'pkcs12', '-export',
        '-in',    $self->certificate->file,
        '-inkey', $self->key->file,
        '-name',  $self->identity,
        '-out',   $self->file,
        '-passout', sprintf( 'file:%s', $pass_file )
    );

    my ( $stdout, $stderr, $exit ) = capture {
        system( $CONFIG->{openssl}, @args );
    };

    if ( $exit != 0 ) {
        croak( sprintf( 'cannot create pkcs12 file: %s', $stderr ) );
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tiny::OpenSSL::PKCS12 - Tiny::OpenSSL::PKCS12 Object

=head1 VERSION

version 0.1.3

=head1 METHODS

=head2 create

Generates a PKCS12 file

    my $p12 = Tiny::OpenSSL::PKCS12->new(
        certificate => $cert,
        key         => $key,
        passphrase  => $passphrase,
        identity    => $identity
    );

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
