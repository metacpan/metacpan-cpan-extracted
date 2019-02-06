package Types::RENEEB;

# ABSTRACT: Several predefined Type::Tiny types

use v5.10;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils ();

our $VERSION = 0.06;

Type::Utils::extends(qw/Types::OTRS Types::Dist/);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::RENEEB - Several predefined Type::Tiny types

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    package TypesTest;

    use strict;
    use warnings;

    use Moo;
    use Types::RENEEB qw(
        DistName DistVersion
        OTRSVersion OTRSVersionWildcard
    );

    has distname     => ( is => 'ro', isa => DistName );
    has distversion  => ( is => 'ro', isa => DistVersion );
    has otrs_version => ( is => 'ro', isa => OTRSVersion );

    sub check_otrs_version {
        OTRSVersion->('2.0.0');
    }

    sub check_otrs_version {
        OTRSVersion->('2.0.x');
    }

    1;

=head1 DESCRIPTION

C<Types::RENEEB> is a collection of types I need very often

=head1 MODULES

These C<Types::> modules are shipped in this distribution:

=over 4

=item * L<Types::Dist>

=item * L<Types::OTRS>

=back

C<Types::RENEEB> inherits the types of the mentioned modules.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
