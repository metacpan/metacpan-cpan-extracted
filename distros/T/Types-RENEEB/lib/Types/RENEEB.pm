package Types::RENEEB;

# ABSTRACT: Several predefined Type::Tiny types

use v5.10;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils ();

Type::Utils::extends(qw/Types::OPM Types::Dist/);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::RENEEB - Several predefined Type::Tiny types

=head1 VERSION

version 0.10

=head1 SYNOPSIS

    package TypesTest;

    use strict;
    use warnings;

    use Moo;
    use Types::RENEEB qw(
        DistName DistVersion
        OPMVersion OPMVersionWildcard
    );

    has distname     => ( is => 'ro', isa => DistName );
    has distversion  => ( is => 'ro', isa => DistVersion );
    has opm_version => ( is => 'ro', isa => OPMVersion );

    sub check_opm_version {
        OPMVersion->('2.0.0');
    }

    sub check_opm_version {
        OPMVersion->('2.0.x');
    }

    1;

=head1 DESCRIPTION

C<Types::RENEEB> is a collection of types I need very often

=head1 MODULES

These C<Types::> modules are shipped in this distribution:

=over 4

=item * L<Types::Dist>

=item * L<Types::OPM>

=back

C<Types::RENEEB> inherits the types of the mentioned modules.

=head2 Types::Dist

=head3 DistFQ

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

=head3 DistName

A name of a distribution

    my $object   = MyClass->new( dist => 'Types-RENEEB' ); # ok

=head3 DistVersion

A version of a distribution

    my $object   = MyClass->new( dist => '0.09' ); # ok

=head3 CPANfile

An instance of L<Module::CPANfile>

    package MyClass;

    use Moo;
    use Types::Dist qw(CPANfile);

    has prereqs => ( is => 'ro', isa => CPANfile, coerce => 1 );

    1;

And then use your class:

    my $object   = MyClass->new( prereqs => '/path/to/cpanfile' );
    my @features = $object->prereqs->features; # call features method from Module::CPANfile

=head2 Types::OPM

=head3 OPMVersion

An OPM version looks like 2.4.5 or 6.0.1.

=head3 OPMVersionWildcard

An OPM version with wildcard as used in Addons. To define a version of the OPM framework
that is needed to install the addon, the developer can use 'x' as a wildcard.

E.g. Addons for OPM 6.x can be installed on any OPM 6 installation, whilst addons that
define 2.4.x as the framework version can only installed on any OPM 2.4 installation, but
not on OPM 2.3 installation.

=head3 OPMFile

An object of L<OPM::Parser>.

It checks if the file exists and can be parsed without an error.

=head3 COERCIONS

=head4 OPMFile

=over 4

=item * From String to OPM::Parser

When a string is given, it is coerced into an L<OPM::Parser> object.

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
