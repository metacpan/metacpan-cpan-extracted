use strict;
use warnings;

package Tiny::OpenSSL::Role::Entity;

# ABSTRACT: Provides common tasks for Tiny::OpenSSL objects.
our $VERSION = '0.1.3'; # VERSION

use Moo::Role;
use Types::Standard qw( Str InstanceOf );
use Path::Tiny;

has ascii => ( is => 'rw', isa => Str );

has file => (
    is      => 'rw',
    isa     => InstanceOf ['Path::Tiny'],
    default => sub { return Path::Tiny->tempfile; }
);

sub write {
    my $self = shift;

    if ( $self->file ) {
        $self->file->spew( $self->ascii );
    }

    return 1;
}

sub load {
    my $self = shift;

    if ( -f $self->file && $self->file->lines > 0 ) {
        $self->ascii( $self->file->slurp );
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tiny::OpenSSL::Role::Entity - Provides common tasks for Tiny::OpenSSL objects.

=head1 VERSION

version 0.1.3

=head1 METHODS

=head2 ascii

The ascii representation of the artifact.

=head2 file

The Path::Tiny object for the file.

=head2 write

Write the artifact to the file.  By default, the file is a Path::Tiny->tempfile, override to store permanently.

=head2 load

Load an existing key.

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
