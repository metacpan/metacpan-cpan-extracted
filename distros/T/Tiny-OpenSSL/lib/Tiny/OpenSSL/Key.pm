use strict;
use warnings;

package Tiny::OpenSSL::Key;

# ABSTRACT: Key object.
our $VERSION = '0.1.3'; # VERSION

use Carp;
use Moo;
use Types::Standard qw( Str InstanceOf Int );
use Path::Tiny;
use Capture::Tiny qw( :all );
use Tiny::OpenSSL::Config qw($CONFIG);

with 'Tiny::OpenSSL::Role::Entity';

has password => ( is => 'rw', isa => Str );

has bits =>
    ( is => 'rw', isa => Int, default => sub { $CONFIG->{key}{bits} } );

sub create {
    my $self = shift;

    my @args = @{ $CONFIG->{key}{opts} };

    if ( -f $self->file && $self->file->lines > 0 ) {
        $self->load;
        return 1;
    }

    my $pass_file;

    if ( $self->password ) {
        $pass_file = Path::Tiny->tempfile;

        $pass_file->spew( $self->password );
        push( @args, sprintf( '-%s', $CONFIG->{key}{block_cipher} ) );
        push( @args, '-passout', sprintf( 'file:%s', $pass_file ) );
    }

    push( @args, '-out', $self->file );
    push( @args, $self->bits );

    my ( $stdout, $stderr, $exit ) = capture {
        system( $CONFIG->{openssl}, @args );
    };

    if ( $exit != 0 ) {
        croak( sprintf( 'cannot create key: %s', $stderr ) );
    }

    $self->ascii( $self->file->slurp );

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tiny::OpenSSL::Key - Key object.

=head1 VERSION

version 0.1.3

=head1 METHODS

=head2 password

Password for the key.

=head2 bits

Number of bits for the key, default is 2048.

=head2 create

Create key.

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
