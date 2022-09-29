package Types::Mojo;

# ABSTRACT: Types related to Mojo

use v5.10;

use strict;
use warnings;

our $VERSION = '0.06'; # VERSION

use Type::Library
   -base,
   -declare => qw( MojoCollection MojoFile MojoFileList MojoUserAgent MojoURL );

use Type::Utils -all;
use Types::Standard -types;

use Carp;
use Mojo::File;
use Mojo::Collection;
use Mojo::URL;
use Scalar::Util qw(blessed);

my $meta = __PACKAGE__->meta;

$meta->add_type(
    name => 'MojoCollection',
    parent => InstanceOf['Mojo::Collection'],
    constraint_generator => sub {
        return $meta->get_type('MojoCollection') if !@_;

        my $check = $_[0] // '';

        croak "Parameter to MojoCollection[`a] expected to be a type constraint; got $check"
            if !blessed $check || !$check->isa('Type::Tiny');

        return sub {
            return if !blessed $_ and $_->isa('Mojo::Collection');

            my $fail = $_->first( sub {
                !$check->( $_ );
            });

            !$fail;
        };
    },
    coercion_generator => sub {
        my ($parent, $child, $param) = @_;
        return $parent->coercion;
    },
    #inline_generator => sub {},
    #deep_explanation => sub {},
);

coerce MojoCollection,
    from ArrayRef, via { Mojo::Collection->new( @{$_} ) }
;

class_type MojoUserAgent, { class => 'Mojo::UserAgent' };

class_type MojoFile, { class => 'Mojo::File' };

coerce MojoFile,
    from Str, via { Mojo::File->new( $_ ) }
;

declare MojoFileList,
    as MojoCollection[MojoFile];

coerce MojoFileList,
    from MojoCollection[Str],
        via {
            my $new = $_->map( sub { Mojo::File->new($_) } );
            $new;
        },
    from ArrayRef[Str],
        via { 
            my @list = @{$_};
            Mojo::Collection->new( map{ Mojo::File->new( $_ ) } @list );
        },
    from ArrayRef[MojoFile],
        via {
            Mojo::Collection->new( @{ $_ } );
        }
;

$meta->add_type(
    name => 'MojoURL',
    parent => InstanceOf['Mojo::URL'],
    constraint_generator => sub {
        return $meta->get_type('MojoURL') if !@_;

        my $type  = $_[0];
        my ($scheme, $secure) = $type =~ m{(.*?)(s\?)?\z};

        return sub {
            return if !blessed $_ and $_->isa('Mojo::URL');

            return 1 if $_->scheme eq $scheme;
            return 1 if $secure && $_->scheme eq $scheme . 's';

            return;
        };
    },
    coercion_generator => sub {
        my ($parent, $child, $param) = @_;
        return $parent->coercion;
    },
);

coerce MojoURL,
    from Str, via { Mojo::URL->new( $_ ) }
;

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::Mojo - Types related to Mojo

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    package MyClass;
    
    use Moo;
    use Types::Mojo qw(MojoFile MojoCollection);
    use Types::Standard qw(Int);
    
    has file => ( is => 'rw', isa => MojoFile, coerce => 1 );
    has coll => ( is => 'rw', isa => MojoCollection, coerce => 1 );
    has ints => ( is => 'rw', isa => MojoCollection[Int] );
    
    1;

In the script

    use MyClass;
    my $object = MyClass->new( file => __FILE__ ); # will be coerced into a Mojo::File object
    say $object->file->move_to( '/path/to/new/location' );

    my $object2 = MyClass->new( coll => [qw/a b/] );
    $object2->coll->each(sub {
        say $_;
    });

=head1 TYPES

=head2 MojoCollection[`a]

An object of L<Mojo::Collection>. Can be parameterized with an other L<Type::Tiny> type.

    has ints => ( is => 'rw', isa => MojoCollection[Int] );

will accept only a C<Mojo::Collection> of integers.

=head2 MojoFile

An object of L<Mojo::File>

=head2 MojoFileList

A C<MojoCollection> of C<MojoFile>s.

=head2 MojoURL[`a]

An object of L<Mojo::URL>. Can be parameterized with a scheme.

    has http_url => ( is => 'rw', isa => MojoURL["https?"] ); # s? means plain or secure -> http or https
    has ftp_url  => ( is => 'rw', isa => MojoURL["ftp"] );

=head2 MojoUserAgent

An object of L<Mojo::UserAgent>

=head1 COERCIONS

These coercions are defined.

=head2 To MojoCollection

=over 4

=item * Array reference to MojoCollection

In a class

    package Test;
    
    use Moo;
    use Types::Mojo qw(MojoCollection);
    
    has 'collection' => ( is => 'ro', isa => MojoCollection, coerce => 1 );
    
    1;

In the script

    use Test;

    use v5.22;
    use feature 'postderef';

    my $obj = Test->new(
        collection => [ 1, 2 ],
    );
    
    my $sqrs = $obj->collection->map( sub { $_ ** 2 } );
    say $_ for $sqrs->to_array->@*;

=back

=head2 To MojoFile

=over 4

=item * String to MojoFile

In a class

    package Test;
    
    use Moo;
    use Types::Mojo qw(MojoFile);
    
    has 'file' => ( is => 'ro', isa => MojoFile, coerce => 1 );
    
    1;

In the script

    use Test;

    use v5.22;

    my $obj = Test->new(
        file => __FILE__,
    );
    
    say $obj->file->slurp;

=back

=head2 To MojoFileList

=over 4

=item * MojoCollection of Strings

In a class

    package Test;
    
    use Moo;
    use Types::Mojo qw(MojoFile);
    
    has 'files' => ( is => 'ro', isa => MojoFileList, coerce => 1 );
    
    1;

In the script

    use Test;

    use v5.22;

    my $obj = Test->new(
        files => Mojo::Collection->(__FILE__),
    );

    for my $file ( @{ $obj->files->to_array } ) {
        say $file->basename;
    }

=item * Array of Strings

In a class

    package Test;
    
    use Moo;
    use Types::Mojo qw(MojoFile);
    
    has 'files' => ( is => 'ro', isa => MojoFileList, coerce => 1 );
    
    1;

In the script

    use Test;

    use v5.22;

    my $obj = Test->new(
        files => [__FILE__],
    );

    for my $file ( @{ $obj->files->to_array } ) {
        say $file->basename;
    }

=item * Array of MojoFile

In a class

    package Test;
    
    use Moo;
    use Types::Mojo qw(MojoFileList);
    
    has 'files' => ( is => 'ro', isa => MojoFileList, coerce => 1 );
    
    1;

In the script

    use Test;

    use v5.22;

    my $obj = Test->new(
        files => [Mojo::File->new(__FILE__)],
    );

    for my $file ( @{ $obj->files->to_array } ) {
        say $file->basename;
    }

=back

=head2 To MojoURL

=over 4

=item * String to MojoURL

In a class

    package Test;
    
    use Moo;
    use Types::Mojo qw(MojoFile);
    
    has 'file' => ( is => 'ro', isa => MojoURL, coerce => 1 );
    
    1;

In the script

    use Test;

    use v5.22;

    my $obj = Test->new(
        url => 'http://perl-services.de',
    );
    
    say $obj->url->host;

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
