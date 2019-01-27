package Types::OTRS;

# ABSTRACT: OTRS related types

use v5.10;

use strict;
use warnings;

use Type::Library
   -base,
   -declare => qw(OTRSVersion OTRSVersionWildcard);

use Type::Utils -all;
use Types::Standard -types;

our $VERSION = '0.02';

declare OTRSVersion =>
    as Str,
    where {
        $_ =~ m{ \A (?: [0-9]+ \. ){2} (?: [0-9]+ ) \z }xms
    };

declare OTRSVersionWildcard =>
    as Str,
    where {
        $_ =~ m{
            \A (?:
                (?: [0-9]+ \. ){2} (?: [0-9]+ ) |
                (?: [0-9]+ \. ){1,2} x
            ) \z
        }xms
    };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::OTRS - OTRS related types

=head1 VERSION

version 0.03

=head1 TYPES

=head2 OTRSVersion

An OTRS version looks like 2.4.5 or 6.0.1.

=head2 OTRSVersionWildcard

An OTRS version with wildcard as used in Addons. To define a version of the OTRS framework
that is needed to install the addon, the developer can use 'x' as a wildcard.

E.g. Addons for OTRS 6.x can be installed on any OTRS 6 installation, whilst addons that
define 2.4.x as the framework version can only installed on any OTRS 2.4 installation, but
not on OTRS 2.3 installation.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
