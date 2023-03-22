package Types::OPM;

# ABSTRACT: OPM related types

use v5.10;

use strict;
use warnings;

use Type::Library
   -base,
   -declare => qw(OPMVersion OPMVersionWildcard OPMFile);

use Type::Utils -all;
use Types::Standard -types;
use OPM::Parser;

declare OPMVersion =>
    as Str,
    where {
        $_ =~ m{ \A (?: [0-9]+ \. ){2} (?: [0-9]+ ) \z }xms
    };

declare OPMVersionWildcard =>
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
    as InstanceOf['OPM::Parser'],
    where {
        $_->opm_file =~ m{\.s?opm\z} and $_->error_string eq '';
    }
;

coerce OPMFile =>
    from Str,
        via {
            return if !-f $_;

            my $p = OPM::Parser->new( opm_file => $_ );
            $p->parse;
            $p;
        }
;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::OPM - OPM related types

=head1 VERSION

version 0.10

=head1 TYPES

=head2 OPMVersion

An OPM version looks like 2.4.5 or 6.0.1.

=head2 OPMVersionWildcard

An OPM version with wildcard as used in Addons. To define a version of the OPM framework
that is needed to install the addon, the developer can use 'x' as a wildcard.

E.g. Addons for OPM 6.x can be installed on any OPM 6 installation, whilst addons that
define 2.4.x as the framework version can only installed on any OPM 2.4 installation, but
not on OPM 2.3 installation.

=head2 OPMFile

An object of L<OPM::Parser>.

It checks if the file exists and can be parsed without an error.

=head1 COERCIONS

=head2 OPMFile

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
