use strict;
use warnings;

package Tiny::OpenSSL::CertificateAuthority;

# ABSTRACT: Certificate Authority object.
our $VERSION = '0.1.3'; # VERSION

use Moo;
use Carp qw(croak);
use Capture::Tiny qw( :all );
use Tiny::OpenSSL::Config qw($CONFIG);

extends 'Tiny::OpenSSL::Certificate';

sub sign {

    my $self = shift;
    my $csr  = shift;
    my $crt  = shift;

    if ( !defined $csr ) {
        croak '$csr is not defined';
    }

    if ( !defined $crt ) {
        croak '$crt is not defined';
    }

    my @args = (
        'ca',              '-policy',
        'policy_anything', '-batch',
        '-cert',           $crt->file,
        '-keyfile',        $self->key->file,
        '-in',             $csr->file,
    );

    my $pass_file;

    if ( $self->key->password ) {

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

    $crt->issuer( $self->subject );
    $crt->ascii( $crt->file->slurp );

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tiny::OpenSSL::CertificateAuthority - Certificate Authority object.

=head1 VERSION

version 0.1.3

=head1 METHODS

=head2 sign

Sign a certificate.

    my $ca->sign($csr);

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
