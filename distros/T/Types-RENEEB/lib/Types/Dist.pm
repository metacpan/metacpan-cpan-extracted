package Types::Dist;
$Types::Dist::VERSION = '0.09';
# ABSTRACT: Types related to distributions (e.g. distributions on CPAN)

use v5.10;

use strict;
use warnings;

use Type::Library
   -base,
   -declare => qw( DistName DistVersion DistFQ CPANfile );

use Type::Utils -all;
use Types::Standard -types;

use Module::CPANfile;

my $distname_re = qr{
    (?:[A-Za-z][A-Za-z0-9]*)
    (?: - [A-Za-z0-9]+ )*
}xms;

my $distversion_re = qr{
    v?
    (?:
        [0-9]+
        (?: \. [0-9]+ )*
    )
}xms;

my $distfq_re = qr{$distname_re-$distversion_re};


declare DistName =>
    as Str,
    where { $_ =~ m{\A$distname_re\z} };

declare DistVersion =>
    as Str,
    where { $_ =~ m{\A$distversion_re\z} };

declare DistFQ =>
    as Str,
    where { $_ =~ m{\A$distfq_re\z} };

class_type CPANfile, { class => 'Module::CPANfile' };

coerce CPANfile,
    from Str, via { Module::CPANfile->load( $_ ) }
;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::Dist - Types related to distributions (e.g. distributions on CPAN)

=head1 VERSION

version 0.09

=head1 TYPES

=head2 DistFQ

I<DistName>-I<DistVersion>

    package MyClass;

    use Moo;
    use Types::Dist qw(DistName);

    has dist => ( is => 'ro', isa => DistName );

    1;

And then use your class:

    my $object   = MyClass->new( dist => 'Types-RENEEB-0.09' );
    my $object   = MyClass->new( dist => '0.09' );         # fails
    my $object   = MyClass->new( dist => 'Types-RENEEB' ); # fails

=head2 DistName

A name of a distribution

    my $object   = MyClass->new( dist => 'Types-RENEEB' ); # ok

=head2 DistVersion

A version of a distribution

    my $object   = MyClass->new( dist => '0.09' ); # ok

=head2 CPANfile

An instance of L<Module::CPANfile>

    package MyClass;

    use Moo;
    use Types::Dist qw(CPANfile);

    has prereqs => ( is => 'ro', isa => CPANfile, coerce => 1 );

    1;

And then use your class:

    my $object   = MyClass->new( prereqs => '/path/to/cpanfile' );
    my @features = $object->prereqs->features; # call features method from Module::CPANfile

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
