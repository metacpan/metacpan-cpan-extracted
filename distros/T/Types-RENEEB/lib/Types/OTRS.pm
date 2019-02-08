package Types::OTRS;

# ABSTRACT: OTRS related types

use v5.10;

use strict;
use warnings;

use Type::Library
   -base,
   -declare => qw(OTRSVersion OTRSVersionWildcard OPMFile);

use Type::Utils -all;
use Types::Standard -types;
use OTRS::OPM::Parser;

our $VERSION = 0.05;

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

declare OPMFile =>
    as InstanceOf['OTRS::OPM::Parser'],
    where {
        $_->opm_file =~ m{\.s?opm\z} and
        ( $_->error_string eq '' or $_->error_string =~ m{Invalid value for maxOccurs} );
    }
;

coerce OPMFile =>
    from Str,
        via {
            return if !-f $_;

            my $p = OTRS::OPM::Parser->new( opm_file => $_ );
            $p->parse;
            $p;
        }
;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::OTRS - OTRS related types

=head1 VERSION

version 0.08

=head1 TYPES

=head2 OTRSVersion

An OTRS version looks like 2.4.5 or 6.0.1.

=head2 OTRSVersionWildcard

An OTRS version with wildcard as used in Addons. To define a version of the OTRS framework
that is needed to install the addon, the developer can use 'x' as a wildcard.

E.g. Addons for OTRS 6.x can be installed on any OTRS 6 installation, whilst addons that
define 2.4.x as the framework version can only installed on any OTRS 2.4 installation, but
not on OTRS 2.3 installation.

=head2 OPMFile

An object of L<OTRS::OPM::Parser>.

It checks if the file exists and can be parsed without an error.

=head1 COERCIONS

=head2 OPMFile

=over 4

=item * From String to OTRS::OPM::Parser

When a string is given, it is coerced into an L<OTRS::OPM::Parser> object.

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
