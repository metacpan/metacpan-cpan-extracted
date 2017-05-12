#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Version/Dotted/Semantic.pm
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
#   Chapter "Dotted Semantic Versioning" is licensed under CC BY 3.0
#   <https://creativecommons.org/licenses/by/3.0/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#pod =for :this This is C<Version::Dotted::Semantic> module documentation. However, read
#pod C<Version::Dotted> module documentation first, since it contains many relevant details.
#pod
#pod =for :those General topics like getting source, building, installing, bug reporting and some
#pod others are covered in the F<README>.
#pod
#pod =for test_synopsis my ( $v, $int, $bool );
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Version::Dotted::Semantic;          # import nothing
#pod     use Version::Dotted::Semantic 'qv';     # import qv
#pod
#pod     # Construct:
#pod     $v = Version::Dotted::Semantic->new( v1 );  # v1.0.0 (at least 3 parts)
#pod     $v = qv( v1 );                              # ditto
#pod     $v = qv( 'v1.2.3.4' );                      # v1.2.3.4
#pod
#pod     # Get parts by name (indexing also works):
#pod     $int = $v->part( 'major' );     # Always defined.
#pod     $int = $v->part( 'minor' );     # ditto
#pod     $int = $v->part( 'patch' );     # ditto
#pod     $int = $v->part( 'trial' );     # May be undefined.
#pod     $int = $v->major;       # Always defined.
#pod     $int = $v->minor;       # ditto
#pod     $int = $v->patch;       # ditto
#pod     $int = $v->trial;       # May be undefined.
#pod
#pod     # Bump the version (indexing also works):
#pod     $v->bump( 'trial' );    # Bump trial part.
#pod     $v->bump( 'patch' );    # Bump patch and drop trial.
#pod     $v->bump( 'minor' );    # Bump minor, reset patch and drop trial.
#pod     $v->bump( 'major' );    # Bump major, reset minor and patch, drop trial.
#pod
#pod     # Release status:
#pod     $bool = $v->is_trial;   # true if version has more than 3 parts.
#pod
#pod     # See Version::Dotted for other methods.
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is subclass of C<Version::Dotted>. Three features distinct it from the parent:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod Version object always has at least 3 parts.
#pod
#pod     $v = qv( v1 );          # == v1.0.0
#pod     $v->part( 0 ) == 1;     # Parts 0, 1, 2 are always defined.
#pod     $v->part( 1 ) == 0;     # Zero if not specified explicitly.
#pod     $v->part( 2 ) == 0;     # ditto
#pod     $v->part( 3 ) == undef; # But may be defined.
#pod
#pod =item *
#pod
#pod First four parts have individual names.
#pod
#pod     $v->major = $v->part( 'major' );    # == $v->part( 0 );
#pod     $v->minor = $v->part( 'minor' );    # == $v->part( 1 );
#pod     $v->patch = $v->part( 'patch' );    # == $v->part( 2 );
#pod     $v->trial = $v->part( 'trial' );    # == $v->part( 3 );
#pod
#pod     $v->bump( 'trial' );  # the same as $v->bump( 3 );
#pod
#pod =item *
#pod
#pod The number of parts defines release status: more than 3 parts denotes trial release.
#pod
#pod     $v = qv( v1 );          # $v == v1.0.0
#pod     $v->is_trial;           # false
#pod     $v->bump( 'trial' );    # $v == v1.0.0.1
#pod     $v->is_trial;           # true
#pod
#pod =back
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =head1 SEMANTIC VERSIONING
#pod
#pod See L<Semantic Versioning 2.0.0|http://semver.org/spec/v2.0.0.html>. It sound very reasonable to
#pod me.
#pod
#pod Unfortunately, Semantic Versioning cannot be applied to Perl modules (maintaining compatibility
#pod with C<version> objects) due to wider character set (letters, hyphens, plus signs, e. g.
#pod 1.0.0-alpha.3+8daebec8a8e1) and specific precedence rules (1.0.0-alpha < 1.0.0).
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =head1 DOTTED SEMANTIC VERSIONING
#pod
#pod Dotted Semantic Versioning is adaptation of Semantic Versioning for Perl and C<version>.
#pod
#pod =head2 Summary
#pod
#pod Given a version number vI<major>.I<minor>.I<patch>, increment the:
#pod
#pod =for :list
#pod * I<major> version when you make incompatible API changes,
#pod * I<minor> version when you add functionality in a backwards-compatible manner, and
#pod * I<patch> version when you make backwards-compatible bug fixes.
#pod
#pod Additional labels for I<trial> versions are available as extension to the
#pod vI<major>.I<minor>.I<patch> format.
#pod
#pod =head2 Introduction
#pod
#pod See L<Semantic Versioning Introduction|http://semver.org/spec/v2.0.0.html#introduction>.
#pod
#pod =head2 Dotted Semantic Versioning Specification
#pod
#pod The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”,
#pod “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in L<RFC
#pod 2119|http://tools.ietf.org/html/rfc2119>.
#pod
#pod =over
#pod
#pod =item 1
#pod
#pod Software using Dotted Semantic Versioning MUST declare a public API. This API could be declared in
#pod the code itself or exist strictly in documentation. However it is done, it should be precise and
#pod comprehensive.
#pod
#pod =item 2
#pod
#pod A I<normal> version number MUST take the form vI<X>.I<Y>.I<Z> where I<X>, I<Y>, and I<Z> are
#pod non-negative integers, and MUST NOT contain leading zeroes. I<X> is the I<major> version, I<Y> is
#pod the I<minor> version, and I<Z> is the I<patch> version. Each element MUST increase numerically. For
#pod instance: v1.9.0 -> v1.10.0 -> v1.11.0.
#pod
#pod =item 3
#pod
#pod Once a versioned package has been released, the contents of that version MUST NOT be modified. Any
#pod modifications MUST be released as a new version.
#pod
#pod =item 4
#pod
#pod Major version zero (v0.I<y>.I<z>) is for initial development. Anything may change at any time. The
#pod public API should not be considered stable.
#pod
#pod =item 5
#pod
#pod Version v1.0.0 defines the public API. The way in which the version number is incremented after
#pod this release is dependent on this public API and how it changes.
#pod
#pod =item 6
#pod
#pod I<Patch> version I<Z> (vI<x>.I<y>.I<Z> | I<x> > 0) MUST be incremented if only backwards compatible
#pod bug fixes are introduced. A bug fix is defined as an internal change that fixes incorrect behavior.
#pod
#pod =item 7
#pod
#pod I<Minor> version I<Y> (vI<x>.I<Y>.I<z> | I<x> > 0) MUST be incremented if new, backwards compatible
#pod functionality is introduced to the public API. It MUST be incremented if any public API
#pod functionality is marked as deprecated. It MAY be incremented if substantial new functionality or
#pod improvements are introduced within the private code. It MAY include patch level changes. Patch
#pod version MUST be reset to 0 when minor version is incremented.
#pod
#pod =item 8
#pod
#pod I<Major> version I<X> (vI<X>.I<y>.I<z> | I<X> > 0) MUST be incremented if any backwards
#pod incompatible changes are introduced to the public API. It MAY include minor and patch level
#pod changes. Patch and minor version MUST be reset to 0 when major version is incremented.
#pod
#pod =item 9
#pod
#pod A I<trial> version MAY be denoted by appending a dot and a series of dot separated numbers
#pod immediately following the patch version. Numbers are non-negative integers and MUST NOT include
#pod leading zeroes. A trial version indicates that the version is unstable and might not satisfy the
#pod intended compatibility requirements as denoted by its associated normal version. Examples:
#pod v1.0.0.1, v1.0.0.1.1, v1.0.0.0.3.7, v1.0.0.7.92.
#pod
#pod =item 10
#pod
#pod (Paragraph excluded, build metadata is not used.)
#pod
#pod =item 11
#pod
#pod Precedence refers to how versions are compared to each other when ordered. Precedence MUST be
#pod calculated by separating the version into numbers in order. Precedence is determined by the first
#pod difference when comparing each of these numbers from left to right. Example: v1.0.0 < v2.0.0 <
#pod v2.1.0 < v2.1.1. A larger set of parts has a higher precedence than a smaller set, if all of the
#pod preceding identifiers are equal. Example: v1.0.0 < v1.0.0.1 < v1.0.0.1.1 < v1.0.0.1.2 < v1.0.0.2 <
#pod v1.0.1.
#pod
#pod =back
#pod
#pod =head2 Why Use Dotted Semantic Versioning?
#pod
#pod See L<Why Use Semantic Versioning?|http://semver.org/spec/v2.0.0.html#why-use-semantic-versioning>.
#pod
#pod =head2 FAQ
#pod
#pod See L<Semantic Versioning FAQ|http://semver.org/spec/v2.0.0.html#faq>.
#pod
#pod =head2 About
#pod
#pod The Dotted Semantic Versioning specification is authored by Van de Bugger. It is adaptation of
#pod Semantic Versioning 2.0.0 for Perl modules.
#pod
#pod L<Semantic Versioning 2.0.0|http://semver.org/spec/v2.0.0.html> is authored by L<Tom
#pod Preston-Werner|http://tom.preston-werner.com/>, inventor of Gravatars and cofounder of GitHub.
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =head1 ADAPTATION DETAILS
#pod
#pod Paragraphs 1..8 of Semantic Versioning define I<normal> version number and establish rules for
#pod I<major>, I<minor> and I<patch>. I would say these paragraphs are core of Semantic Versioning.
#pod Happily they can be applied for versioning Perl modules with almost no modifications. I just added
#pod leading 'v' character to version numbers.
#pod
#pod Paragraphs 9..11 define auxiliary stuff (I<pre-release version>, I<build metadata>) and version
#pod precedence rules. Unfortunately, these paragraphs cannot be applied as-is for versioning Perl
#pod modules, they require adaptation.
#pod
#pod =head2 Paragraph 9, pre-release version
#pod
#pod Semantic Versioning uses term I<pre-release>. I<Pre-release> version is denoted by appending minus
#pod sign and a series of dot separated identifiers which comprise alphanumeric and hyphen.
#pod
#pod Dotted version cannot include letters and hyphens, a workaround is required.
#pod
#pod First, let us call it I<trial> (instead of I<pre-release>), it is more Perlish and CPANish. (BTW,
#pod it is also more correct term, because trial versions are released, actually.)
#pod
#pod Second, let us reduce trial identifier alphabet to digits (instead of alphanumeric and hyphen; it
#pod fully meets Semantic Versioning, they call such identifiers "numeric").
#pod
#pod Third, let us denote I<trial> version by dot. Dot is already used to separate parts of I<normal>
#pod version: I<major>, I<minor>, and I<patch>. However, the number of parts in I<normal> version is
#pod fixed, so we can easily distinguish I<trial>: the first 3 parts compose I<normal> version,
#pod everything behind I<the third dot> (if any) compose I<trial>.
#pod
#pod =head2 Paragraph 10, build metadata
#pod
#pod I<Build metadata> is denoted by appending a plus sign and dot separated identifiers.
#pod
#pod Dotted version cannot include plus sign, a workaround is required (again).
#pod
#pod Replacement plus sign with dot (like replacing hyphen with dot for I<trial> versions) does not
#pod work: I<build metadata> would be indistinguishable from I<trial> version. Fortunately, I<build
#pod metadata> is not mandatory, so let us drop it completely.
#pod
#pod =head2 Paragraph 11, precedence
#pod
#pod This paragraph defines version precedence. It prescribes a I<pre-release> version has lower
#pod precedence than a I<normal> version with the same I<major>, I<minor>, and I<patch>: 1.0.0-alpha <
#pod 1.0.0.
#pod
#pod This looks good for Semantic Versioning with hyphen and alphanumeric I<pre-release> identifiers,
#pod but it does not look good for Dotted Semantic Versioning with only dots and numeric I<trial>
#pod identifiers: 1.0.0.1 < 1.0.0.
#pod
#pod So, let us use natural precedence as it implemented by C<version> module: 1.0.0 < 1.0.0.1. A
#pod I<trial> release can be placed before I<normal> release by choosing appropriate I<major>, I<minor>,
#pod and I<patch> versions. For example, a series of I<trial> releases preceding version 1.0.0 could be
#pod 0.99.99.1, 0.99.99.2, 0.999.999.3, etc, a series of I<trial> releases preceding 1.1.0 could be
#pod 1.0.99.1, 1.0.99.2, etc.
#pod
#pod =cut

package Version::Dotted::Semantic;

use strict;
use warnings;

# ABSTRACT: (Adapted) Semantic Versioning
our $VERSION = 'v0.0.1'; # VERSION

use parent 'Version::Dotted';

use Scalar::Util qw{};

# --------------------------------------------------------------------------------------------------

#pod =Attribute min_len
#pod
#pod Minimal number of parts, read-only.
#pod
#pod     $int = Version::Dotted::Semantic->min_len;  # == 3
#pod
#pod C<Version::Dotted::Semantic> objects always have at least 3 parts.
#pod
#pod =cut

sub min_len { 3 };           ## no critic ( RequireFinalReturn )

# --------------------------------------------------------------------------------------------------

my $names = {
    major => 0,
    minor => 1,
    patch => 2,
    trial => 3,
};

# --------------------------------------------------------------------------------------------------

#pod =method major
#pod
#pod =method minor
#pod
#pod =method patch
#pod
#pod Returns the first, the second, and the third part of the version, respectively.
#pod
#pod     $int = $v->major;   # the first part
#pod     $int = $v->minor;   # the second part
#pod     $int = $v->patch;   # the third part
#pod
#pod Since version always has at least 3 parts, these methods never return C<undef>.
#pod
#pod =method trial
#pod
#pod Returns the fourth part of the version.
#pod
#pod     $int = $v->trial;   # the fourth part
#pod
#pod The method returns C<undef> if version has less than 4 parts.
#pod
#pod =cut

while ( my ( $name, $idx ) = each( %$names ) ) {
    my $sub = sub {
        my ( $self ) = @_;
        return $self->{ version }->[ $idx ];
    };
    no strict 'refs';                   ## no critic ( ProhibitNoStrict )
    *{ $name } = $sub;
};

# --------------------------------------------------------------------------------------------------

for my $name ( qw{ part bump } ) {
    my $sub = sub {
        my ( $self, $idx ) = @_;
        if ( not Scalar::Util::looks_like_number( $idx ) ) {
            $idx = $names->{ $idx } // do {
                $self->_warn( "Invalid version part name '$idx'" );
                return;
            };
        };
        no strict 'refs';               ## no critic ( ProhibitNoStrict )
        return &{ "Version::Dotted::$name" }( $self, $idx );
    };
    no strict 'refs';                   ## no critic ( ProhibitNoStrict )
    *{ $name } = $sub;
};

# --------------------------------------------------------------------------------------------------

#pod =method is_trial
#pod
#pod Returns true in case of trial version, and false otherwise.
#pod
#pod     $bool = $v->is_trial;
#pod
#pod A version is considered trial if it has more than 3 parts:
#pod
#pod     qv( v1.2.3.4 )->is_trial;   # true
#pod     qv( v1.2.4   )->is_trial;   # false
#pod
#pod =cut

sub is_trial {
    my ( $self ) = @_;
    return @{ $self->{ version } } > 3;
};

# --------------------------------------------------------------------------------------------------

1;

# --------------------------------------------------------------------------------------------------

#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod = L<Version::Dotted>
#pod = L<Semantic Versioning 2.0.0|http://semver.org/spec/v2.0.0.html>
#pod
#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod =over
#pod
#pod =item Everything except "Dotted Semantic Versioning" chapter
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
#pod =item "Dotted Semantic Versioning" chapter
#pod
#pod Licensed under L<CC BY 3.0|https://creativecommons.org/licenses/by/3.0>.
#pod
#pod =back
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

Version::Dotted::Semantic - (Adapted) Semantic Versioning

=head1 VERSION

Version v0.0.1, released on 2017-01-04 21:35 UTC.

=head1 WHAT?

C<Version::Dotted> and its subclasses are I<authoring time> extensions to core C<version> class:
they complement C<version> with bump operation and implement alternative trial version criteria.

This is C<Version::Dotted::Semantic> module documentation. However, read
C<Version::Dotted> module documentation first, since it contains many relevant details.

General topics like getting source, building, installing, bug reporting and some
others are covered in the F<README>.

=for test_synopsis my ( $v, $int, $bool );

=head1 SYNOPSIS

    use Version::Dotted::Semantic;          # import nothing
    use Version::Dotted::Semantic 'qv';     # import qv

    # Construct:
    $v = Version::Dotted::Semantic->new( v1 );  # v1.0.0 (at least 3 parts)
    $v = qv( v1 );                              # ditto
    $v = qv( 'v1.2.3.4' );                      # v1.2.3.4

    # Get parts by name (indexing also works):
    $int = $v->part( 'major' );     # Always defined.
    $int = $v->part( 'minor' );     # ditto
    $int = $v->part( 'patch' );     # ditto
    $int = $v->part( 'trial' );     # May be undefined.
    $int = $v->major;       # Always defined.
    $int = $v->minor;       # ditto
    $int = $v->patch;       # ditto
    $int = $v->trial;       # May be undefined.

    # Bump the version (indexing also works):
    $v->bump( 'trial' );    # Bump trial part.
    $v->bump( 'patch' );    # Bump patch and drop trial.
    $v->bump( 'minor' );    # Bump minor, reset patch and drop trial.
    $v->bump( 'major' );    # Bump major, reset minor and patch, drop trial.

    # Release status:
    $bool = $v->is_trial;   # true if version has more than 3 parts.

    # See Version::Dotted for other methods.

=head1 DESCRIPTION

This is subclass of C<Version::Dotted>. Three features distinct it from the parent:

=over

=item *

Version object always has at least 3 parts.

    $v = qv( v1 );          # == v1.0.0
    $v->part( 0 ) == 1;     # Parts 0, 1, 2 are always defined.
    $v->part( 1 ) == 0;     # Zero if not specified explicitly.
    $v->part( 2 ) == 0;     # ditto
    $v->part( 3 ) == undef; # But may be defined.

=item *

First four parts have individual names.

    $v->major = $v->part( 'major' );    # == $v->part( 0 );
    $v->minor = $v->part( 'minor' );    # == $v->part( 1 );
    $v->patch = $v->part( 'patch' );    # == $v->part( 2 );
    $v->trial = $v->part( 'trial' );    # == $v->part( 3 );

    $v->bump( 'trial' );  # the same as $v->bump( 3 );

=item *

The number of parts defines release status: more than 3 parts denotes trial release.

    $v = qv( v1 );          # $v == v1.0.0
    $v->is_trial;           # false
    $v->bump( 'trial' );    # $v == v1.0.0.1
    $v->is_trial;           # true

=back

=head1 CLASS ATTRIBUTES

=head2 min_len

Minimal number of parts, read-only.

    $int = Version::Dotted::Semantic->min_len;  # == 3

C<Version::Dotted::Semantic> objects always have at least 3 parts.

=head1 OBJECT METHODS

=head2 major

=head2 minor

=head2 patch

Returns the first, the second, and the third part of the version, respectively.

    $int = $v->major;   # the first part
    $int = $v->minor;   # the second part
    $int = $v->patch;   # the third part

Since version always has at least 3 parts, these methods never return C<undef>.

=head2 trial

Returns the fourth part of the version.

    $int = $v->trial;   # the fourth part

The method returns C<undef> if version has less than 4 parts.

=head2 is_trial

Returns true in case of trial version, and false otherwise.

    $bool = $v->is_trial;

A version is considered trial if it has more than 3 parts:

    qv( v1.2.3.4 )->is_trial;   # true
    qv( v1.2.4   )->is_trial;   # false

=for comment ---------------------------------------------------------------------------------------

=for comment ---------------------------------------------------------------------------------------

=for comment ---------------------------------------------------------------------------------------

=head1 SEMANTIC VERSIONING

See L<Semantic Versioning 2.0.0|http://semver.org/spec/v2.0.0.html>. It sound very reasonable to
me.

Unfortunately, Semantic Versioning cannot be applied to Perl modules (maintaining compatibility
with C<version> objects) due to wider character set (letters, hyphens, plus signs, e. g.
1.0.0-alpha.3+8daebec8a8e1) and specific precedence rules (1.0.0-alpha < 1.0.0).

=for comment ---------------------------------------------------------------------------------------

=head1 DOTTED SEMANTIC VERSIONING

Dotted Semantic Versioning is adaptation of Semantic Versioning for Perl and C<version>.

=head2 Summary

Given a version number vI<major>.I<minor>.I<patch>, increment the:

=over 4

=item *

I<major> version when you make incompatible API changes,

=item *

I<minor> version when you add functionality in a backwards-compatible manner, and

=item *

I<patch> version when you make backwards-compatible bug fixes.

=back

Additional labels for I<trial> versions are available as extension to the
vI<major>.I<minor>.I<patch> format.

=head2 Introduction

See L<Semantic Versioning Introduction|http://semver.org/spec/v2.0.0.html#introduction>.

=head2 Dotted Semantic Versioning Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”,
“RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in L<RFC
2119|http://tools.ietf.org/html/rfc2119>.

=over

=item 1

Software using Dotted Semantic Versioning MUST declare a public API. This API could be declared in
the code itself or exist strictly in documentation. However it is done, it should be precise and
comprehensive.

=item 2

A I<normal> version number MUST take the form vI<X>.I<Y>.I<Z> where I<X>, I<Y>, and I<Z> are
non-negative integers, and MUST NOT contain leading zeroes. I<X> is the I<major> version, I<Y> is
the I<minor> version, and I<Z> is the I<patch> version. Each element MUST increase numerically. For
instance: v1.9.0 -> v1.10.0 -> v1.11.0.

=item 3

Once a versioned package has been released, the contents of that version MUST NOT be modified. Any
modifications MUST be released as a new version.

=item 4

Major version zero (v0.I<y>.I<z>) is for initial development. Anything may change at any time. The
public API should not be considered stable.

=item 5

Version v1.0.0 defines the public API. The way in which the version number is incremented after
this release is dependent on this public API and how it changes.

=item 6

I<Patch> version I<Z> (vI<x>.I<y>.I<Z> | I<x> > 0) MUST be incremented if only backwards compatible
bug fixes are introduced. A bug fix is defined as an internal change that fixes incorrect behavior.

=item 7

I<Minor> version I<Y> (vI<x>.I<Y>.I<z> | I<x> > 0) MUST be incremented if new, backwards compatible
functionality is introduced to the public API. It MUST be incremented if any public API
functionality is marked as deprecated. It MAY be incremented if substantial new functionality or
improvements are introduced within the private code. It MAY include patch level changes. Patch
version MUST be reset to 0 when minor version is incremented.

=item 8

I<Major> version I<X> (vI<X>.I<y>.I<z> | I<X> > 0) MUST be incremented if any backwards
incompatible changes are introduced to the public API. It MAY include minor and patch level
changes. Patch and minor version MUST be reset to 0 when major version is incremented.

=item 9

A I<trial> version MAY be denoted by appending a dot and a series of dot separated numbers
immediately following the patch version. Numbers are non-negative integers and MUST NOT include
leading zeroes. A trial version indicates that the version is unstable and might not satisfy the
intended compatibility requirements as denoted by its associated normal version. Examples:
v1.0.0.1, v1.0.0.1.1, v1.0.0.0.3.7, v1.0.0.7.92.

=item 10

(Paragraph excluded, build metadata is not used.)

=item 11

Precedence refers to how versions are compared to each other when ordered. Precedence MUST be
calculated by separating the version into numbers in order. Precedence is determined by the first
difference when comparing each of these numbers from left to right. Example: v1.0.0 < v2.0.0 <
v2.1.0 < v2.1.1. A larger set of parts has a higher precedence than a smaller set, if all of the
preceding identifiers are equal. Example: v1.0.0 < v1.0.0.1 < v1.0.0.1.1 < v1.0.0.1.2 < v1.0.0.2 <
v1.0.1.

=back

=head2 Why Use Dotted Semantic Versioning?

See L<Why Use Semantic Versioning?|http://semver.org/spec/v2.0.0.html#why-use-semantic-versioning>.

=head2 FAQ

See L<Semantic Versioning FAQ|http://semver.org/spec/v2.0.0.html#faq>.

=head2 About

The Dotted Semantic Versioning specification is authored by Van de Bugger. It is adaptation of
Semantic Versioning 2.0.0 for Perl modules.

L<Semantic Versioning 2.0.0|http://semver.org/spec/v2.0.0.html> is authored by L<Tom
Preston-Werner|http://tom.preston-werner.com/>, inventor of Gravatars and cofounder of GitHub.

=for comment ---------------------------------------------------------------------------------------

=head1 ADAPTATION DETAILS

Paragraphs 1..8 of Semantic Versioning define I<normal> version number and establish rules for
I<major>, I<minor> and I<patch>. I would say these paragraphs are core of Semantic Versioning.
Happily they can be applied for versioning Perl modules with almost no modifications. I just added
leading 'v' character to version numbers.

Paragraphs 9..11 define auxiliary stuff (I<pre-release version>, I<build metadata>) and version
precedence rules. Unfortunately, these paragraphs cannot be applied as-is for versioning Perl
modules, they require adaptation.

=head2 Paragraph 9, pre-release version

Semantic Versioning uses term I<pre-release>. I<Pre-release> version is denoted by appending minus
sign and a series of dot separated identifiers which comprise alphanumeric and hyphen.

Dotted version cannot include letters and hyphens, a workaround is required.

First, let us call it I<trial> (instead of I<pre-release>), it is more Perlish and CPANish. (BTW,
it is also more correct term, because trial versions are released, actually.)

Second, let us reduce trial identifier alphabet to digits (instead of alphanumeric and hyphen; it
fully meets Semantic Versioning, they call such identifiers "numeric").

Third, let us denote I<trial> version by dot. Dot is already used to separate parts of I<normal>
version: I<major>, I<minor>, and I<patch>. However, the number of parts in I<normal> version is
fixed, so we can easily distinguish I<trial>: the first 3 parts compose I<normal> version,
everything behind I<the third dot> (if any) compose I<trial>.

=head2 Paragraph 10, build metadata

I<Build metadata> is denoted by appending a plus sign and dot separated identifiers.

Dotted version cannot include plus sign, a workaround is required (again).

Replacement plus sign with dot (like replacing hyphen with dot for I<trial> versions) does not
work: I<build metadata> would be indistinguishable from I<trial> version. Fortunately, I<build
metadata> is not mandatory, so let us drop it completely.

=head2 Paragraph 11, precedence

This paragraph defines version precedence. It prescribes a I<pre-release> version has lower
precedence than a I<normal> version with the same I<major>, I<minor>, and I<patch>: 1.0.0-alpha <
1.0.0.

This looks good for Semantic Versioning with hyphen and alphanumeric I<pre-release> identifiers,
but it does not look good for Dotted Semantic Versioning with only dots and numeric I<trial>
identifiers: 1.0.0.1 < 1.0.0.

So, let us use natural precedence as it implemented by C<version> module: 1.0.0 < 1.0.0.1. A
I<trial> release can be placed before I<normal> release by choosing appropriate I<major>, I<minor>,
and I<patch> versions. For example, a series of I<trial> releases preceding version 1.0.0 could be
0.99.99.1, 0.99.99.2, 0.999.999.3, etc, a series of I<trial> releases preceding 1.1.0 could be
1.0.99.1, 1.0.99.2, etc.

=head1 SEE ALSO

=over 4

=item L<Version::Dotted>

=item L<Semantic Versioning 2.0.0|http://semver.org/spec/v2.0.0.html>

=back

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

=over

=item Everything except "Dotted Semantic Versioning" chapter

Copyright (C) 2017 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=item "Dotted Semantic Versioning" chapter

Licensed under L<CC BY 3.0|https://creativecommons.org/licenses/by/3.0>.

=back

=cut
