#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Version/Dotted/Odd.pm
#
#   Copyright © 2017 Van de Bugger.
#
#   This file is part of perl-Version-Dotted.
#
#   perl-Version-Dotted is free software: you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation, either version
#   3 of the License, or (at your option) any later version.
#
#   perl-Version-Dotted is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Version-Dotted. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#pod =for :this This is C<Version::Dotted::Odd> module documentation. However, read C<Version::Dotted>
#pod module documentation first, since it contains many relevant details.
#pod
#pod =for :those General topics like getting source, building, installing, bug reporting and some
#pod others are covered in the F<README>.
#pod
#pod =for test_synopsis my ( $v, $bool );
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Version::Dotted::Odd;       # import nothing
#pod     use Version::Dotted::Odd 'qv';  # import qv
#pod
#pod     # Construct:
#pod     $v = Version::Dotted::Odd->new( v1.0 );     # v1.0.0 (at least 3 parts)
#pod     $v = qv( v1.0.2.5 );    # v1.0.2.5
#pod
#pod     # Release status:
#pod     $bool = $v->is_trial;   # true if the second part is odd.
#pod
#pod     # See Version::Dotted for other methods.
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is subclass of C<Version::Dotted>. Two features distinct it from the parent:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod Version object always has at least 3 parts.
#pod
#pod     $v = qv( v1 );          # v1.0.0
#pod     $v->part( 0 ) == 1;     # Parts 0, 1, 2 are always defined.
#pod     $v->part( 1 ) == 0;     # Zero if not specified explicitly.
#pod     $v->part( 2 ) == 0;     # ditto
#pod     $v->part( 3 ) == undef; # But may be defined.
#pod
#pod =item *
#pod
#pod The second part defines the release status: odd number denotes a trial release.
#pod
#pod     $v = qv( v1.0 );        # $v == v1.0.0
#pod     $v->is_trial;           # false
#pod     $v->bump( 1 );          # $v == v1.1.0
#pod     $v->is_trial;           # true
#pod
#pod Such versioning scheme was used by Linux kernel (between 1.0 and 2.6) and still used by Perl.
#pod
#pod =back
#pod
#pod
#pod =cut

package Version::Dotted::Odd;

use strict;
use warnings;

# ABSTRACT: Odd/even versioning scheme
our $VERSION = 'v0.0.1'; # VERSION

use parent 'Version::Dotted';

# --------------------------------------------------------------------------------------------------

#pod =Attribute min_len
#pod
#pod Minimal number of parts, read-only.
#pod
#pod     $int = Version::Dotted::Odd->min_len;   # == 3
#pod
#pod C<Version::Dotted::Odd> objects always have at least 3 parts.
#pod
#pod =cut

sub min_len { 3 };           ## no critic ( RequireFinalReturn )

# --------------------------------------------------------------------------------------------------

#pod =method is_trial
#pod
#pod Returns true in case of trial version, and false otherwise.
#pod
#pod     $bool = $v->is_trial;
#pod
#pod A version is considered trial if the second part is an odd number:
#pod
#pod     qv( v1.1.3 )->is_trial;     # true
#pod     qv( v1.2.0 )->is_trial;     # false
#pod
#pod =cut

sub is_trial {
    my ( $self ) = @_;
    my $v = $self->{ version };
    return $v->[ 1 ] % 2 != 0;
};

# --------------------------------------------------------------------------------------------------

1;

# --------------------------------------------------------------------------------------------------

#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod = L<Version::Dotted>
#pod = L<Odd-numbered versions for development releases|https://en.wikipedia.org/wiki/Software_versioning#Odd-numbered_versions_for_development_releases>
#pod
#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2017 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

#   ------------------------------------------------------------------------------------------------
#
#   file: doc/what.pod
#
#   This file is part of perl-Version-Dotted.
#
#   ------------------------------------------------------------------------------------------------

#pod =encoding UTF-8
#pod
#pod =head1 WHAT?
#pod
#pod C<Version::Dotted> and its subclasses are I<authoring time> extensions to core C<version> class:
#pod they complement C<version> with bump operation and implement alternative trial version criteria.
#pod
#pod =cut

# end of file #


# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Version::Dotted::Odd - Odd/even versioning scheme

=head1 VERSION

Version v0.0.1, released on 2017-01-04 21:35 UTC.

=head1 WHAT?

C<Version::Dotted> and its subclasses are I<authoring time> extensions to core C<version> class:
they complement C<version> with bump operation and implement alternative trial version criteria.

This is C<Version::Dotted::Odd> module documentation. However, read C<Version::Dotted>
module documentation first, since it contains many relevant details.

General topics like getting source, building, installing, bug reporting and some
others are covered in the F<README>.

=for test_synopsis my ( $v, $bool );

=head1 SYNOPSIS

    use Version::Dotted::Odd;       # import nothing
    use Version::Dotted::Odd 'qv';  # import qv

    # Construct:
    $v = Version::Dotted::Odd->new( v1.0 );     # v1.0.0 (at least 3 parts)
    $v = qv( v1.0.2.5 );    # v1.0.2.5

    # Release status:
    $bool = $v->is_trial;   # true if the second part is odd.

    # See Version::Dotted for other methods.

=head1 DESCRIPTION

This is subclass of C<Version::Dotted>. Two features distinct it from the parent:

=over

=item *

Version object always has at least 3 parts.

    $v = qv( v1 );          # v1.0.0
    $v->part( 0 ) == 1;     # Parts 0, 1, 2 are always defined.
    $v->part( 1 ) == 0;     # Zero if not specified explicitly.
    $v->part( 2 ) == 0;     # ditto
    $v->part( 3 ) == undef; # But may be defined.

=item *

The second part defines the release status: odd number denotes a trial release.

    $v = qv( v1.0 );        # $v == v1.0.0
    $v->is_trial;           # false
    $v->bump( 1 );          # $v == v1.1.0
    $v->is_trial;           # true

Such versioning scheme was used by Linux kernel (between 1.0 and 2.6) and still used by Perl.

=back

=head1 CLASS ATTRIBUTES

=head2 min_len

Minimal number of parts, read-only.

    $int = Version::Dotted::Odd->min_len;   # == 3

C<Version::Dotted::Odd> objects always have at least 3 parts.

=head1 OBJECT METHODS

=head2 is_trial

Returns true in case of trial version, and false otherwise.

    $bool = $v->is_trial;

A version is considered trial if the second part is an odd number:

    qv( v1.1.3 )->is_trial;     # true
    qv( v1.2.0 )->is_trial;     # false

=head1 SEE ALSO

=over 4

=item L<Version::Dotted>

=item L<Odd-numbered versions for development releases|https://en.wikipedia.org/wiki/Software_versioning#Odd-numbered_versions_for_development_releases>

=back

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
