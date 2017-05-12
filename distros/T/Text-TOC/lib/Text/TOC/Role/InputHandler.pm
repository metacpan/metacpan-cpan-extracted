package Text::TOC::Role::InputHandler;
{
  $Text::TOC::Role::InputHandler::VERSION = '0.10';
}

use strict;
use warnings;
use namespace::autoclean;

use File::Slurp qw( read_file );
use Path::Class qw( file );
use Text::TOC::Types qw( ArrayRef File Filter HashRef Node Str );
use Tie::IxHash;

use Moose::Role;
use MooseX::Params::Validate qw( validated_list );

requires '_process_file';

has _files => (
    traits  => ['Array'],
    is      => 'bare',
    isa     => ArrayRef [File],
    default => sub { [] },
    handles => {
        _add_file => 'push',
        files     => 'elements',
    },
);

has _documents => (
    is      => 'bare',
    isa     => 'Tie::IxHash',
    default => sub { Tie::IxHash->new() },
    handles => {
        _add_document => 'STORE',
        documents     => 'Values',
        document      => 'FETCH',
    },
);

has _filter => (
    is       => 'ro',
    isa      => Filter,
    coerce   => 1,
    init_arg => 'filter',
);

has nodes => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => ArrayRef [Node],
    default => sub { [] },
    handles => {
        _add_node => 'push',
    },
);

sub add_file {
    my $self = shift;
    my ( $file, $content ) = validated_list(
        \@_,
        file    => { isa => File, coerce => 1 },
        content => { isa => Str, optional => 1 },
    );

    $self->_add_file($file);

    unless ( defined $content ) {
        die "No such file: $file" unless -f $file;
        $content = read_file( $file->stringify() );
    }

    my $document = $self->_process_file( $file, $content );

    $self->_add_document( $file->stringify() => $document );

    return;
}

1;

# ABSTRACT: A role for input handlers


__END__
=pod

=head1 NAME

Text::TOC::Role::InputHandler - A role for input handlers

=head1 VERSION

version 0.10

=head1 DESCRIPTION

This role defines the API and partial implementation for input handlers.

=for Pod::Coverage add_file

=head1 REQUIRED METHODS

This role requires one method:

=head2 $handler->_process_file( $file, $content )

This method will receive a L<Path::Class::File> object as its first
argument and the file's content as its second.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

