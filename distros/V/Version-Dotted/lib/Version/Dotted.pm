#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Version/Dotted.pm
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

#pod =for :this This is C<Version::Dotted> module documentation. Read it first because it contains many
#pod relevant details, and use one of subclasses.
#pod
#pod =for :those General topics like getting source, building, installing, bug reporting and some others
#pod are covered in the F<README>.
#pod
#pod =for test_synopsis my ( $v, $i, $int, @int, $str, $bool );
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use Version::Dotted;        # import nothing
#pod     use Version::Dotted 'qv';   # import qv
#pod
#pod     # Construct:
#pod     $v = Version::Dotted->new( v1.2.3 );    # same as qv( v1.2.3 )
#pod     $v = qv( v1.2.3 );      # v1.2.3
#pod     $v = qv( 'v1.2.0' );    # v1.2 (trailing zero parts ignored)
#pod     $v = qv( 'v1' );        # v1
#pod
#pod     # Access parts:
#pod     @int = $v->parts;       # Get all parts.
#pod     $int = $v->part( $i );  # Get i-th part (zero-based).
#pod
#pod     # Bump the version:
#pod     $v->bump( $i );         # Bump i-th part
#pod                             # and drop all parts behind i-th.
#pod
#pod     # Determine release status:
#pod     $bool = $v->is_trial;
#pod
#pod     # Stringify:
#pod     $str = $v->stringify;   # "v1.2.3"
#pod     $str = "$v";            # ditto
#pod
#pod     # Compare:
#pod     $bool = $v >= v1.2.3;
#pod     $bool = $v <=> 'v1.2.3';
#pod
#pod =head1 DESCRIPTION
#pod
#pod =head2 Purpose
#pod
#pod C<Version::Dotted> is I<authoring time> extension to C<version>. It means C<Version::Dotted> and
#pod its subclasses are intended to be used in authoring tools (like C<Dist::Zilla> plugins) when author
#pod prepares a distribution. C<Version::Dotted> and its subclasses serve for two purposes:
#pod
#pod =over
#pod
#pod =item 1
#pod
#pod To bump a dotted version.
#pod
#pod =item 2
#pod
#pod To implement alternative trial version criteria not depending on underscore character.
#pod
#pod =back
#pod
#pod C<Version::Dotted> is I<not> required to build, install, and use module(s) from prebuilt
#pod distribution, core C<version> works at these stages.
#pod
#pod See also L</WHY?>.
#pod
#pod =head2 Types of Versions
#pod
#pod Historically, two types of version numbers are used in Perl: L<decimal|/Decimal Versions> and
#pod L<dotted|/Dotted Versions>.
#pod
#pod C<Version::Dotted> handles only dotted versions, no support for decimal versions is provided
#pod intentionally.
#pod
#pod =head2 Bumping
#pod
#pod "Bumping" means incrementing a version part by one and dropping all the parts behind the
#pod incremented. For example, bumping the third part of C<v1.2.3> gives C<v1.2.4>, bumping the second
#pod part of C<v1.2.4> gives C<v1.3> (the third part is dropped).
#pod
#pod =head2 Trial Versions
#pod
#pod Firstly, C<Version::Dotted> prefers "trial" term to "alpha" (see L</Non-Stable Releases>).
#pod
#pod Secondly, trial versions are not denoted by underscore character anymore (see L</WHY?>).
#pod C<Version::Dotted> defines interface, exact criteria are implemented in subclasses.
#pod
#pod =head2 Parent(s)
#pod
#pod C<Version::Dotted> is heavily influenced by C<Perl::Version>, but C<Version::Dotted> is not a
#pod subclass of C<Perl::Version>.
#pod
#pod C<Version::Dotted> it is a subclass of C<version>. C<Version::Dotted> extends C<version> —
#pod C<Version::Dotted> objects are modifiable, but it also narrows C<version> — C<Version::Dotted>
#pod creates only dotted (aka dotted-decimal) version objects.
#pod
#pod =head2 Error Reporting
#pod
#pod The class reports error by C<warnings::warnif>. It gives flexibility to the caller: warning may be
#pod either suppressed
#pod
#pod     no warnings 'Version::Dotted';
#pod
#pod or made fatal:
#pod
#pod     use warnings FATAL => 'Version::Dotted';
#pod
#pod =cut

package Version::Dotted;

use strict;
use warnings;
use warnings::register;
use version 0.77 qw{};

# ABSTRACT: Bump a dotted version, check if version is trial
our $VERSION = 'v0.0.1'; # VERSION

use parent 'version';
use overload (
    'cmp' => \&_cmp,
    '<=>' => \&_cmp,
);

# --------------------------------------------------------------------------------------------------

#pod =Attribute min_len
#pod
#pod Minimal number of parts, read-only.
#pod
#pod     $int = Version::Dotted->min_len;    # == 1
#pod
#pod Objects are maintained to have at least minimal number of parts. In C<Version::Dotted> minimal
#pod number of parts is 1, subclasses may raise the bar.
#pod
#pod =cut

sub min_len { 1 };           ## no critic ( RequireFinalReturn )

sub _max_len { 1000 };                  ## no critic ( RequireFinalReturn )
# TODO: INTMAX?

sub _warn {
    my ( $self, $message ) = @_;
    warnings::warnif( 'Version::Dotted', $message );
    return;
};

# --------------------------------------------------------------------------------------------------

#pod =Method C<new>
#pod
#pod Constructs a new version object.
#pod
#pod     $obj = Version::Dotted->new( $arg );
#pod
#pod The constructor accepts one argument and creates dotted version object. An argument can be either
#pod integer number (C<1>),  floating point number (C<1.2>), v-string (C<v1.2>), or string (with or
#pod without leading v: C<'1.2'>, C<'v1.2'>), or C<version> object. Trailing zero parts may be stripped
#pod (if number of parts exceeds required minimum), leading zeros in parts are insignificant:
#pod
#pod     Version::Dotted->new( 1.2.0 ) == Version::Dotted->new( v1.2 );
#pod     Version::Dotted->new( 1.002 ) == Version::Dotted->new( v1.2 );
#pod
#pod However, to avoid surprises (see L</Leading Zeros> and L</Trailing Zeros>) it is better to stick to
#pod using v-strings or strings, using numbers is not recommended (and may be prohibited in future).
#pod
#pod =caveat Leading Zeros
#pod
#pod Leading zeros in parts are insignificant:
#pod
#pod     qv( v01.02.03 ) == v1.2.3;
#pod     qv( 1.002 )     == v1.2;
#pod
#pod However, Perl interprets numbers with leading zero as octal, so be aware of:
#pod
#pod     qv( 010     ) == v8;    # 010 == 8
#pod     qv( 010.011 ) == v89;   # 010.011 eq 8 . 9 eq "89"
#pod
#pod To avoid surprises stick to using v-strings or strings:
#pod
#pod     qv(  v010      ) == v10;
#pod     qv(  v010.011  ) == v10.10;
#pod     qv( 'v010.011' ) == v10.10;
#pod
#pod =caveat Trailing Zeros
#pod
#pod Perl ignores trailing zeros in floating point numbers:
#pod
#pod     1.200 == 1.2;
#pod
#pod so
#pod
#pod     qv( 1.200 ) == v1.2;    # not v1.200
#pod
#pod To avoid such surprises stick to using v-strings or strings:
#pod
#pod     qv( v1.200  ) == v1.200;
#pod     qv( '1.200' ) == v1.200;
#pod
#pod =cut

sub new {
    my ( $class, $arg ) = @_;
    my $v;
    if ( eval { $arg->isa( 'version' ) } ) {
        $v = $class->declare( 0 );                      # Create a new version object.
        $v->{ version } = [ @{ $arg->{ version } } ];   # Copy version parts.
    } else {
        if ( not defined $arg ) {
            $class->_warn( "Use of undefined value to construct version" );
            $arg = 'v0';
        };
        #   `declare` can die if `$arg` is not valid. It will complain on Version/Dotted.pm, which
        #   is not good — we have to translate errors to caller code. Unfortunately, tricks with
        #   @version::CARP_NOT does not work. @version::vpp:CARP_NOT does work, but only if vpp
        #   module is used (which is not normal case). @version::vxs::CARP_NOT is not respected at
        #   all. So we have to catch and rethrow exception in order to edit source location.
        eval {
            $v = $class->declare( $arg );
            1;
        } or do {
            if ( $@ =~ s{ \h at \h .*?/Version/Dotted\.pm \h line \h \d+ \.? \n? \z }{}x ) {
                $class->_warn( $@ );
                $v = $class->declare( 0 );
            } else {
                die $@;                 ## no critic ( RequireCarping )
            };
        };
    };
    return $v->_norm();
};

# --------------------------------------------------------------------------------------------------

#pod =Method C<parse>
#pod
#pod Prints warning "Method 'parse' is not supported" and returns C<undef>.
#pod
#pod =cut

sub parse {
    my ( $class ) = @_;
    $class->_warn( "Method 'parse' is not supported" );
    return;
};

# --------------------------------------------------------------------------------------------------

# If $arg is a version object, return it as-is. Otherwise create a version object and return it.
sub _obj {
    my ( $self, $arg ) = @_;
    if ( not eval { $arg->isa( 'version' ) } ) {
        $arg = $self->new( $arg );
    };
    return $arg;
};

# --------------------------------------------------------------------------------------------------

#pod =method C<parts>
#pod
#pod Returns all parts of the version.
#pod
#pod     @int = $v->parts;   # Get all parts.
#pod
#pod In scalar context it gives number of parts in the version object:
#pod
#pod     $int = $v->parts;   # Get number of parts.
#pod
#pod =cut

sub parts {
    my ( $self ) = @_;
    return @{ $self->{ version } };
};

# --------------------------------------------------------------------------------------------------

#pod =method C<part>
#pod
#pod Returns i-th part of the version.
#pod
#pod     $int = $v->part( $i );  # Get i-th part.
#pod
#pod If index is larger than actual number of version parts minus one, C<undef> is returned.
#pod
#pod Negative part index causes warning but works like index to regular Perl array: C<-1> is index
#pod of the last version part, C<-2> — second last, etc.
#pod
#pod =cut

sub part {
    my ( $self, $idx ) = @_;
    $idx >= 0 or $self->_warn( "Negative version part index '$idx'" );
    return $self->{ version }->[ $idx ];
};

# --------------------------------------------------------------------------------------------------

#pod =method C<bump>
#pod
#pod Bumps i-th version part.
#pod
#pod     $v->bump( $i );
#pod
#pod "Bumping" means incrementing i-th version part by one I<and> dropping all the parts behind i-th:
#pod
#pod     $v = qv( v1.2.3 );  # $v == v1.2.3
#pod     $v->bump( 3 );      # $v == v1.2.3.1
#pod     $v->bump( 2 );      # $v == v1.2.4
#pod     $v->bump( 1 );      # $v == v1.3
#pod     $v->bump( 0 );      # $v == v2
#pod
#pod If index is larger than actual number of version parts, missed parts are autovivified:
#pod
#pod     $v->bump( 5 );      # $v == v2.0.0.0.0.1
#pod
#pod Negative part index causes warning but works.
#pod
#pod The method returns reference to version object:
#pod
#pod     $v->bump( 2 )->stringify;
#pod
#pod =cut

sub bump {
    my ( $self, $idx ) = @_;
    my $v = $self->{ version };
    if ( $idx < - abs( @$v ) ) {
        $self->_warn( "Invalid version part index '$idx'" );
        return;
    };
    $idx >= 0 or $self->_warn( "Negative version part index '$idx'" );
    ++ $v->[ $idx ];
    if ( $idx == -1 ) {
        # -1 denotes the last part, nothing to delete behind it.
    } else {
        # Ok, it is not the last part, let us delete everything behind it:
        splice( @$v, $idx + 1 );
    };
    return $self->_norm();
};

# --------------------------------------------------------------------------------------------------

#pod =method C<is_trial>
#pod
#pod Returns true in case of trial version, and false otherwise.
#pod
#pod     $bool = $v->is_trial;
#pod
#pod This method always returns false, but descendants will likely redefine the method.
#pod
#pod See also L</Non-Stable Releases>.
#pod
#pod =cut

sub is_trial {
    my ( $self ) = @_;
    return '';
};

# --------------------------------------------------------------------------------------------------

#pod =method C<is_alpha>
#pod
#pod The method does the same as C<is_trial> but prints a warning.
#pod
#pod =cut

sub is_alpha {
    my ( $self ) = @_;
    $self->_warn( "Method 'is_alpha' is not recommended, use 'is_trial' instead" );
    return $self->is_trial;
};

# --------------------------------------------------------------------------------------------------

#pod =operator C<E<lt>=E<gt>>
#pod
#pod Compares two versions.
#pod
#pod     $v <=> $other;
#pod
#pod The operator is inherited from parent's class (see L<version/"How to compare version objects">).
#pod However, there is a subtle difference: if C<$other> is not a version object, it converted to a
#pod version object using C<new> (I<not> parent's C<parse>).
#pod
#pod Other comparison operators (e. g. C<E<lt>>, C<E<gt>>, C<E<lt>=>, etc) are created by Perl.
#pod
#pod =operator C<cmp>
#pod
#pod The same as C<E<lt>=E<gt>>.
#pod
#pod =cut

sub _cmp {
    my ( $self, $other, $swap ) = @_;
    $other = $self->_obj( $other );
    no strict 'refs';                       ## no critic ( ProhibitNoStrict )
    return &{ 'version::(cmp' }( $self, $other, $swap );
};

# --------------------------------------------------------------------------------------------------

# Normalize version representation.
sub _norm {
    my ( $self ) = @_;
    my $v = $self->{ version };
    my $m = $self->min_len;
    # Make sure there are no undefined elements in the array (which can appear after `bump`):
    $_ // ( $_ = 0 ) for @$v;
    # Make sure we have at least $m parts:
    while ( @$v < $m ) {
        push( @$v, 0 );
    };
    # Drop zero parts from the end (but keep at lest $m parts):
    while ( @$v > $m and $v->[ -1 ] == 0 ) {
      -- $#$v;
    };
    # Update version string representation:
    my $s = 'v' . join( '.', @$v );
    $self->{ original } = $s;
    # Check number of parts:
    @$v <= $self->_max_len or $self->_warn( "Bad version '$s': too many parts" );
    return $self;
};

# --------------------------------------------------------------------------------------------------

#pod =method C<stringify>
#pod
#pod Returns version string with leading 'v' character.
#pod
#pod     $str = $v->stringify;
#pod
#pod See also L</Stringification>.
#pod
#pod =operator ""
#pod
#pod Returns version string.
#pod
#pod     $str = "$v";
#pod
#pod The same as C<stringify>.
#pod
#pod =note Stringification
#pod
#pod The parent class C<version> works with dotted and decimal versions and has three stringification
#pod methods:
#pod
#pod     $v->stringify;  # as close to the original representatiion as possible
#pod     $v->numify;     # (convert to) decimal version
#pod     $v->normal;     # (convert to) dotted version with leading 'v'
#pod
#pod C<normal> and C<numify> are used to convert a version to specified form, dotted or decimal
#pod respectively, regardless of its actual type:
#pod
#pod     version->parse( 1.003010 )->normal;     # eq "v1.3.10"
#pod     version->declare( v1.3.10 )->numify;    # eq "1.003010"
#pod
#pod C<Version::Dotted> works with dotted versions only. C<normal> returns dotted version string with
#pod leading 'v' character (like parent does), C<stringify> does exactly the same, C<numify> is not
#pod supported:
#pod
#pod     $v->normal;     # dotted version with leading 'v'
#pod     $v->stringify;  # same as normal
#pod     $v->numify;     # prints warning & returns undef
#pod
#pod Practically it means C<Version::Dotted> has only one stringification method. Since there is no
#pod place for conversion, C<stringify> is the preferred name for it.
#pod
#pod =cut

sub stringify {
    my ( $self ) = @_;
    return $self->{ original };
};

# --------------------------------------------------------------------------------------------------

#pod =method C<normal>
#pod
#pod The same as C<stringify>.
#pod
#pod     $str = $v->normal;
#pod
#pod See also L</Stringification>.
#pod
#pod =cut

#   Parent method will reconstruct the version string from `version` attribute and ensure it has at
#   least 3 parts.

*normal = \&stringify;

# --------------------------------------------------------------------------------------------------

#pod =method C<numify>
#pod
#pod Prints warning "Method 'numify' is not supported" and returns C<undef>.
#pod
#pod See also L</Stringification>.
#pod
#pod =cut

sub numify {
    my ( $self ) = @_;
    $self->_warn( "Method 'numify' is not supported" );
    return;
};

# --------------------------------------------------------------------------------------------------

#pod =head1 EXPORT
#pod
#pod The module exports nothing by default.
#pod
#pod The module installs C<qv> function (I<not> a method) into caller namespace by explicit request:
#pod
#pod     use Version::Dotted 'qv';
#pod
#pod If caller module already has C<qv> function, warning is issued and function is redefined.
#pod
#pod Note: C<version> exports C<qv> by default, if caller package does not have C<qv> function yet.
#pod
#pod The module (unlike to C<version>) does not play any tricks with importer's C<VERSION> and/or
#pod C<UNIVERSAL::VERSION>.
#pod
#pod =function qv
#pod
#pod Shortcut for C<Version::Dotted-E<gt>new>.
#pod
#pod     $v = qv( $arg );    # same as $v = Version::Dotted->new( $arg );
#pod
#pod (If the function is imported from C<Version::Dotted> subclass, it would be shortcut for
#pod C<Version::Dotted::Subclass-E<gt>new>.)
#pod
#pod The function is prototyped. It takes one scalar argument:
#pod
#pod     ( $v, $w ) = qv v1.2.3, v1.2.3;
#pod
#pod C<$v> will be a C<Dotted::Version> object, C<$w> will be a v-string. (C<version>'s C<qv> grabs
#pod entire list but uses only the first argument, C<$w> will be undefined.)
#pod
#pod Note: There is no function C<qv> in C<Version::Dotted> package, the function is installed into
#pod importer package by explicit request, see L</"EXPORT">.
#pod
#pod =cut

#   We have to redefine parents' import. Otherwise we will export `qv` into importer namespace by
#   default. Explicit import of `qv` is a good idea, though.

sub import {                                    ## no critic ( RequireArgUnpacking )
    my ( $class, @list ) = @_;
    my $pkg = caller();
    my %args = map( { $_ => 1 } @list );
    if ( delete( $args{ qv } ) ) {
        my $qv = $pkg . '::qv';
        no strict 'refs';                       ## no critic ( ProhibitNoStrict )
        no warnings qw{ redefine prototype };   ## no critic ( ProhibitNoWarnings )
        $class->_warn( "Subroutine '$qv' redefined" ) if defined &$qv;
        *$qv = sub ($) {
            return $class->new( @_ );
        };
    };
    if ( %args ) {
        $class->_warn( "Bad $class import: " . join( ', ', map( { "'$_'" } keys( %args ) ) ) );
    };
    return;
};

1;

#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =note Using C<version>
#pod
#pod C<version> is an Perl core module. It serves for two purposes:
#pod
#pod =over
#pod
#pod =item 1
#pod
#pod Declare package version. C<version> module can be used either explicitly (works for any Perl
#pod version):
#pod
#pod     package Assa;
#pod     use version 0.77; our $VERSION = version->declare( 'v1.2.3' );
#pod
#pod or implicitly (works for Perl 5.12.0 or later):
#pod
#pod     package Assa v1.2.3;
#pod
#pod In the second case Perl automatically assigns C<$VERSION> variable an object of C<version> class.
#pod
#pod =item 2
#pod
#pod Compare package versions:
#pod
#pod     version->parse( $Assa::VERSION ) >= 'v1.2.3';
#pod
#pod =back
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =note Decimal Versions
#pod
#pod Decimal version is just a floating-point number. In Perl decimal version can be represented by
#pod floating-point number, string, or C<version> object:
#pod
#pod     0.003010                        # floating-point number
#pod     '0.003010'                      # string
#pod     version->parse( '0.003010' )    # version object
#pod
#pod Floating-point numbers can be compared, but lose trailing zeros. Strings do not lose trailing
#pod zeros, but string comparison operators are not suitable for comparing versions. C<version> objects
#pod does not lose trailing zeros, can be easily compared, but cannot be modified.
#pod
#pod See also: L<version::Internals/Decimal Versions>.
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =note Dotted Versions
#pod
#pod Dotted (aka dotted-decimal) version is a series of parts joined with dots, each part is a cardinal
#pod (non-negative) integer. In Perl dotted versions can be represented by v-strings, strings, or
#pod C<version> objects:
#pod
#pod     v0.10.3                         # v-string
#pod     'v0.10.3'                       # string
#pod     version->declare( 'v0.10.3' )   # version object
#pod
#pod V-strings can be easily compared (by C<cmp>, C<eq> and other string comparison operators), but are
#pod not suitable for printing. Strings can be easily printed but string comparison operators are not
#pod suitable for comparing versions. C<version> objects can be easily compared and printed, but cannot
#pod be modified. (C<Version::Dotted> objects can be.)
#pod
#pod Leading 'v' character is optional: in strings — always, in v-strings — if there are two or more
#pod dots. However, using 'v' character is recommended for clarity and readability.
#pod
#pod See also: L<version::Internals/Dotted-Decimal Versions>.
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =note Conversion Rules
#pod
#pod To convert a decimal version to dotted one: (1) insert dot after each third digit in fractional
#pod part, and then (2) strip leading zeros in every part:
#pod
#pod     1.003010 -(1)-> 1.003.010 -(2)-> 1.3.10
#pod
#pod Obviously any possible decimal version can be conversed to corresponding dotted version.
#pod
#pod To convert a dotted version to decimal one: (1) prepend each part (except the first) with leading
#pod zeros to have exactly 3 digits in each part, and then (2) strip all the dots except the first:
#pod
#pod     1.3.10 -(1)-> 1.003.010 -(2)-> 1.003010
#pod
#pod Not all dotted version can be converted to corresponding decimal one. First, all parts (except the
#pod first) of a dotted version must comprise not more than 3 digits. Second, dotted version should not
#pod contain too many parts due to limited precision of floating-point numbers.
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =note Non-Stable Releases
#pod
#pod Perl terminology in this area is not well-defined and not consistently used:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod The C<version> module declares any version with underscore character (e. g. C<'v1.2.3_4'>) to be an
#pod "alpha" version. C<version::Internals> refers to CPAN convention "to note unstable releases with an
#pod underscore in the version string".
#pod
#pod =item *
#pod
#pod In turn, C<CPAN::Meta::Spec> defines release status as one of: C<stable>, C<testing>, and
#pod C<unstable>. Word "alpha" is used in the description of C<unstable> release, while C<testing>
#pod release is described as "beta". There is also requirement that C<stable> release version should not
#pod contain underscore. (There is no requirement that C<unstanble> and C<testing> releases should
#pod contain underscore.)
#pod
#pod =item *
#pod
#pod pause.perl.org site has section named "Developer Releases" which is about releasing "code for
#pod testing". Such releases should either have version with underscore or "-TRIAL" suffix.
#pod
#pod =item *
#pod
#pod meta::cpan site in the list of module releases shows "DEV" (which likely means "developer release")
#pod after versions containing underscore.
#pod
#pod =item *
#pod
#pod C<dzil> tool has C<--trial> command line option to build a "release that PAUSE will not index".
#pod
#pod =back
#pod
#pod "Alpha" term used by C<version> module (and some others) is a bad choice because it has strong
#pod association with "beta" and "release candidate" terms, which do not have any support by C<version>.
#pod
#pod "Trial" term sounds more neutral and generic: a trial release could be either "alpha", "beta",
#pod "release candidate", "unstable", "testing", or "developer release".
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =note Underscores
#pod
#pod TODO
#pod
#pod =for comment ---------------------------------------------------------------------------------------
#pod
#pod =head1 SEE ALSO
#pod
#pod =begin :list
#pod
#pod = L<version>
#pod
#pod Parent class. It provides most of functionality, can work with decimal versions, but does not
#pod provide any modifiers. Release status depends on presence of underscore character in version.
#pod
#pod = L<Perl::Version>
#pod
#pod An alternative to C<version>. It works with both decimal and dotted versions, provides modification
#pod operations. Release status depends on presence of underscore character in version.
#pod
#pod = L<Version::Next>
#pod
#pod It provides authoring time subroutine to "increment module version numbers simply and correctly",
#pod works with both dotted and decimal versions, but it "no longer supports dotted-decimals with alpha
#pod elements".
#pod
#pod = L<SemVer>
#pod
#pod It implements L<Semantic Versioning 1.0.0|http://semver.org/spec/v1.0.0.html> with no changes (?).
#pod C<SemVer> allows alphanumeric pre-release versions like C<'1.2.3-alpha1'> and orders them properly:
#pod 1.2.3-alpha < 1.2.3-beta < 1.2.3. However, C<SemVer> is not I<authoring time> tool, it should be
#pod used in runtime also to provide correct ordering: C<version> does not recognize properly
#pod pre-release alphanumeric versions.
#pod
#pod = L<Version::Dotted::Semantic>
#pod
#pod Subclass implementing adaptation of Semantic Versioning, part of this distribution.
#pod
#pod = L<Version::Dotted::Odd>
#pod
#pod Subclass implementing odd/even versioning scheme, part of this distribution.
#pod
#pod =end :list
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
#   ------------------------------------------------------------------------------------------------
#
#   file: doc/why.pod
#
#   This file is part of perl-Version-Dotted.
#
#   ------------------------------------------------------------------------------------------------

#pod =encoding UTF-8
#pod
#pod =head1 WHY?
#pod
#pod C<version> is an official Perl module for declare and compare versions, it is recommended by
#pod C<Task::Kensho> and used by Perl itself (C<package Assa v1.2.3;> automatically assigns C<$VERSION>
#pod variable an object of C<version> class). Unfortunately, the module does not provide any method to
#pod bump a version.
#pod
#pod C<Perl::Version> is another module recommended by C<Task::Kensho>. This module provides method(s)
#pod to bump a version, e. g.:
#pod
#pod     my $v = Perl::Version->new( 'v1.2.3' );
#pod     $v->inc_alpha;
#pod     "$v";   # eq 'v1.2.3_01'
#pod
#pod I used such code with no problem… until C<version> 0.9913. C<version> 0.9913 changed interpretation
#pod of underscore character: before C<'v1.2.3_01'> was interpreted as C<'v1.2.3.1'> (+ trial flag,
#pod of course), starting from 0.9913 it is interpreted as C<'v1.2.301'> (+ trial flag).
#pod
#pod I believe there were good reasons for this change (e. g. current C<version> behavior matches Perl
#pod behavior and so reduces the mess), but this change breaks C<Perl::Version> as well as my code
#pod because
#pod
#pod     version->parse( 'v1.2.3_01' ) < 'v1.2.4'
#pod
#pod was true before, is false now.
#pod
#pod Thus, C<Perl::Version> is broken and it is not clear when and I<how> it will be fixed. But
#pod
#pod =over
#pod
#pod =item 1
#pod
#pod I want a method to bump a version, and want it now.
#pod
#pod =item 2
#pod
#pod I want a method to represent trial versions, and want it is compatible with C<version> either
#pod pre-0.9913 or post-0.9912 (i. e. >= 0.77).
#pod
#pod =item 3
#pod
#pod I want these methods to work with dotted versions, decimal versions are out of my interest.
#pod
#pod =back
#pod
#pod (BTW: Requirement #2 effectively means that new method should not rely on underscores.)
#pod
#pod C<Version::Dotted> fulfills these requirements.
#pod
#pod =cut

# end of file #


# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Version::Dotted - Bump a dotted version, check if version is trial

=head1 VERSION

Version v0.0.1, released on 2017-01-04 21:35 UTC.

=head1 WHAT?

C<Version::Dotted> and its subclasses are I<authoring time> extensions to core C<version> class:
they complement C<version> with bump operation and implement alternative trial version criteria.

This is C<Version::Dotted> module documentation. Read it first because it contains many
relevant details, and use one of subclasses.

General topics like getting source, building, installing, bug reporting and some others
are covered in the F<README>.

=for test_synopsis my ( $v, $i, $int, @int, $str, $bool );

=head1 SYNOPSIS

    use Version::Dotted;        # import nothing
    use Version::Dotted 'qv';   # import qv

    # Construct:
    $v = Version::Dotted->new( v1.2.3 );    # same as qv( v1.2.3 )
    $v = qv( v1.2.3 );      # v1.2.3
    $v = qv( 'v1.2.0' );    # v1.2 (trailing zero parts ignored)
    $v = qv( 'v1' );        # v1

    # Access parts:
    @int = $v->parts;       # Get all parts.
    $int = $v->part( $i );  # Get i-th part (zero-based).

    # Bump the version:
    $v->bump( $i );         # Bump i-th part
                            # and drop all parts behind i-th.

    # Determine release status:
    $bool = $v->is_trial;

    # Stringify:
    $str = $v->stringify;   # "v1.2.3"
    $str = "$v";            # ditto

    # Compare:
    $bool = $v >= v1.2.3;
    $bool = $v <=> 'v1.2.3';

=head1 DESCRIPTION

=head2 Purpose

C<Version::Dotted> is I<authoring time> extension to C<version>. It means C<Version::Dotted> and
its subclasses are intended to be used in authoring tools (like C<Dist::Zilla> plugins) when author
prepares a distribution. C<Version::Dotted> and its subclasses serve for two purposes:

=over

=item 1

To bump a dotted version.

=item 2

To implement alternative trial version criteria not depending on underscore character.

=back

C<Version::Dotted> is I<not> required to build, install, and use module(s) from prebuilt
distribution, core C<version> works at these stages.

See also L</WHY?>.

=head2 Types of Versions

Historically, two types of version numbers are used in Perl: L<decimal|/Decimal Versions> and
L<dotted|/Dotted Versions>.

C<Version::Dotted> handles only dotted versions, no support for decimal versions is provided
intentionally.

=head2 Bumping

"Bumping" means incrementing a version part by one and dropping all the parts behind the
incremented. For example, bumping the third part of C<v1.2.3> gives C<v1.2.4>, bumping the second
part of C<v1.2.4> gives C<v1.3> (the third part is dropped).

=head2 Trial Versions

Firstly, C<Version::Dotted> prefers "trial" term to "alpha" (see L</Non-Stable Releases>).

Secondly, trial versions are not denoted by underscore character anymore (see L</WHY?>).
C<Version::Dotted> defines interface, exact criteria are implemented in subclasses.

=head2 Parent(s)

C<Version::Dotted> is heavily influenced by C<Perl::Version>, but C<Version::Dotted> is not a
subclass of C<Perl::Version>.

C<Version::Dotted> it is a subclass of C<version>. C<Version::Dotted> extends C<version> —
C<Version::Dotted> objects are modifiable, but it also narrows C<version> — C<Version::Dotted>
creates only dotted (aka dotted-decimal) version objects.

=head2 Error Reporting

The class reports error by C<warnings::warnif>. It gives flexibility to the caller: warning may be
either suppressed

    no warnings 'Version::Dotted';

or made fatal:

    use warnings FATAL => 'Version::Dotted';

=head1 EXPORT

The module exports nothing by default.

The module installs C<qv> function (I<not> a method) into caller namespace by explicit request:

    use Version::Dotted 'qv';

If caller module already has C<qv> function, warning is issued and function is redefined.

Note: C<version> exports C<qv> by default, if caller package does not have C<qv> function yet.

The module (unlike to C<version>) does not play any tricks with importer's C<VERSION> and/or
C<UNIVERSAL::VERSION>.

=head1 CLASS ATTRIBUTES

=head2 min_len

Minimal number of parts, read-only.

    $int = Version::Dotted->min_len;    # == 1

Objects are maintained to have at least minimal number of parts. In C<Version::Dotted> minimal
number of parts is 1, subclasses may raise the bar.

=head1 CLASS METHODS

=head2 C<new>

Constructs a new version object.

    $obj = Version::Dotted->new( $arg );

The constructor accepts one argument and creates dotted version object. An argument can be either
integer number (C<1>),  floating point number (C<1.2>), v-string (C<v1.2>), or string (with or
without leading v: C<'1.2'>, C<'v1.2'>), or C<version> object. Trailing zero parts may be stripped
(if number of parts exceeds required minimum), leading zeros in parts are insignificant:

    Version::Dotted->new( 1.2.0 ) == Version::Dotted->new( v1.2 );
    Version::Dotted->new( 1.002 ) == Version::Dotted->new( v1.2 );

However, to avoid surprises (see L</Leading Zeros> and L</Trailing Zeros>) it is better to stick to
using v-strings or strings, using numbers is not recommended (and may be prohibited in future).

=head2 C<parse>

Prints warning "Method 'parse' is not supported" and returns C<undef>.

=head1 OBJECT METHODS

=head2 C<parts>

Returns all parts of the version.

    @int = $v->parts;   # Get all parts.

In scalar context it gives number of parts in the version object:

    $int = $v->parts;   # Get number of parts.

=head2 C<part>

Returns i-th part of the version.

    $int = $v->part( $i );  # Get i-th part.

If index is larger than actual number of version parts minus one, C<undef> is returned.

Negative part index causes warning but works like index to regular Perl array: C<-1> is index
of the last version part, C<-2> — second last, etc.

=head2 C<bump>

Bumps i-th version part.

    $v->bump( $i );

"Bumping" means incrementing i-th version part by one I<and> dropping all the parts behind i-th:

    $v = qv( v1.2.3 );  # $v == v1.2.3
    $v->bump( 3 );      # $v == v1.2.3.1
    $v->bump( 2 );      # $v == v1.2.4
    $v->bump( 1 );      # $v == v1.3
    $v->bump( 0 );      # $v == v2

If index is larger than actual number of version parts, missed parts are autovivified:

    $v->bump( 5 );      # $v == v2.0.0.0.0.1

Negative part index causes warning but works.

The method returns reference to version object:

    $v->bump( 2 )->stringify;

=head2 C<is_trial>

Returns true in case of trial version, and false otherwise.

    $bool = $v->is_trial;

This method always returns false, but descendants will likely redefine the method.

See also L</Non-Stable Releases>.

=head2 C<is_alpha>

The method does the same as C<is_trial> but prints a warning.

=head2 C<stringify>

Returns version string with leading 'v' character.

    $str = $v->stringify;

See also L</Stringification>.

=head2 C<normal>

The same as C<stringify>.

    $str = $v->normal;

See also L</Stringification>.

=head2 C<numify>

Prints warning "Method 'numify' is not supported" and returns C<undef>.

See also L</Stringification>.

=head1 FUNCTIONS

=head2 qv

Shortcut for C<Version::Dotted-E<gt>new>.

    $v = qv( $arg );    # same as $v = Version::Dotted->new( $arg );

(If the function is imported from C<Version::Dotted> subclass, it would be shortcut for
C<Version::Dotted::Subclass-E<gt>new>.)

The function is prototyped. It takes one scalar argument:

    ( $v, $w ) = qv v1.2.3, v1.2.3;

C<$v> will be a C<Dotted::Version> object, C<$w> will be a v-string. (C<version>'s C<qv> grabs
entire list but uses only the first argument, C<$w> will be undefined.)

Note: There is no function C<qv> in C<Version::Dotted> package, the function is installed into
importer package by explicit request, see L</"EXPORT">.

=head1 OPERATORS

=head2 C<E<lt>=E<gt>>

Compares two versions.

    $v <=> $other;

The operator is inherited from parent's class (see L<version/"How to compare version objects">).
However, there is a subtle difference: if C<$other> is not a version object, it converted to a
version object using C<new> (I<not> parent's C<parse>).

Other comparison operators (e. g. C<E<lt>>, C<E<gt>>, C<E<lt>=>, etc) are created by Perl.

=head2 C<cmp>

The same as C<E<lt>=E<gt>>.

=head2 ""

Returns version string.

    $str = "$v";

The same as C<stringify>.

=head1 CAVEATS

=head2 Leading Zeros

Leading zeros in parts are insignificant:

    qv( v01.02.03 ) == v1.2.3;
    qv( 1.002 )     == v1.2;

However, Perl interprets numbers with leading zero as octal, so be aware of:

    qv( 010     ) == v8;    # 010 == 8
    qv( 010.011 ) == v89;   # 010.011 eq 8 . 9 eq "89"

To avoid surprises stick to using v-strings or strings:

    qv(  v010      ) == v10;
    qv(  v010.011  ) == v10.10;
    qv( 'v010.011' ) == v10.10;

=head2 Trailing Zeros

Perl ignores trailing zeros in floating point numbers:

    1.200 == 1.2;

so

    qv( 1.200 ) == v1.2;    # not v1.200

To avoid such surprises stick to using v-strings or strings:

    qv( v1.200  ) == v1.200;
    qv( '1.200' ) == v1.200;

=head1 NOTES

=head2 Stringification

The parent class C<version> works with dotted and decimal versions and has three stringification
methods:

    $v->stringify;  # as close to the original representatiion as possible
    $v->numify;     # (convert to) decimal version
    $v->normal;     # (convert to) dotted version with leading 'v'

C<normal> and C<numify> are used to convert a version to specified form, dotted or decimal
respectively, regardless of its actual type:

    version->parse( 1.003010 )->normal;     # eq "v1.3.10"
    version->declare( v1.3.10 )->numify;    # eq "1.003010"

C<Version::Dotted> works with dotted versions only. C<normal> returns dotted version string with
leading 'v' character (like parent does), C<stringify> does exactly the same, C<numify> is not
supported:

    $v->normal;     # dotted version with leading 'v'
    $v->stringify;  # same as normal
    $v->numify;     # prints warning & returns undef

Practically it means C<Version::Dotted> has only one stringification method. Since there is no
place for conversion, C<stringify> is the preferred name for it.

=head2 Using C<version>

C<version> is an Perl core module. It serves for two purposes:

=over

=item 1

Declare package version. C<version> module can be used either explicitly (works for any Perl
version):

    package Assa;
    use version 0.77; our $VERSION = version->declare( 'v1.2.3' );

or implicitly (works for Perl 5.12.0 or later):

    package Assa v1.2.3;

In the second case Perl automatically assigns C<$VERSION> variable an object of C<version> class.

=item 2

Compare package versions:

    version->parse( $Assa::VERSION ) >= 'v1.2.3';

=back

=head2 Decimal Versions

Decimal version is just a floating-point number. In Perl decimal version can be represented by
floating-point number, string, or C<version> object:

    0.003010                        # floating-point number
    '0.003010'                      # string
    version->parse( '0.003010' )    # version object

Floating-point numbers can be compared, but lose trailing zeros. Strings do not lose trailing
zeros, but string comparison operators are not suitable for comparing versions. C<version> objects
does not lose trailing zeros, can be easily compared, but cannot be modified.

See also: L<version::Internals/Decimal Versions>.

=head2 Dotted Versions

Dotted (aka dotted-decimal) version is a series of parts joined with dots, each part is a cardinal
(non-negative) integer. In Perl dotted versions can be represented by v-strings, strings, or
C<version> objects:

    v0.10.3                         # v-string
    'v0.10.3'                       # string
    version->declare( 'v0.10.3' )   # version object

V-strings can be easily compared (by C<cmp>, C<eq> and other string comparison operators), but are
not suitable for printing. Strings can be easily printed but string comparison operators are not
suitable for comparing versions. C<version> objects can be easily compared and printed, but cannot
be modified. (C<Version::Dotted> objects can be.)

Leading 'v' character is optional: in strings — always, in v-strings — if there are two or more
dots. However, using 'v' character is recommended for clarity and readability.

See also: L<version::Internals/Dotted-Decimal Versions>.

=head2 Conversion Rules

To convert a decimal version to dotted one: (1) insert dot after each third digit in fractional
part, and then (2) strip leading zeros in every part:

    1.003010 -(1)-> 1.003.010 -(2)-> 1.3.10

Obviously any possible decimal version can be conversed to corresponding dotted version.

To convert a dotted version to decimal one: (1) prepend each part (except the first) with leading
zeros to have exactly 3 digits in each part, and then (2) strip all the dots except the first:

    1.3.10 -(1)-> 1.003.010 -(2)-> 1.003010

Not all dotted version can be converted to corresponding decimal one. First, all parts (except the
first) of a dotted version must comprise not more than 3 digits. Second, dotted version should not
contain too many parts due to limited precision of floating-point numbers.

=head2 Non-Stable Releases

Perl terminology in this area is not well-defined and not consistently used:

=over

=item *

The C<version> module declares any version with underscore character (e. g. C<'v1.2.3_4'>) to be an
"alpha" version. C<version::Internals> refers to CPAN convention "to note unstable releases with an
underscore in the version string".

=item *

In turn, C<CPAN::Meta::Spec> defines release status as one of: C<stable>, C<testing>, and
C<unstable>. Word "alpha" is used in the description of C<unstable> release, while C<testing>
release is described as "beta". There is also requirement that C<stable> release version should not
contain underscore. (There is no requirement that C<unstanble> and C<testing> releases should
contain underscore.)

=item *

pause.perl.org site has section named "Developer Releases" which is about releasing "code for
testing". Such releases should either have version with underscore or "-TRIAL" suffix.

=item *

meta::cpan site in the list of module releases shows "DEV" (which likely means "developer release")
after versions containing underscore.

=item *

C<dzil> tool has C<--trial> command line option to build a "release that PAUSE will not index".

=back

"Alpha" term used by C<version> module (and some others) is a bad choice because it has strong
association with "beta" and "release candidate" terms, which do not have any support by C<version>.

"Trial" term sounds more neutral and generic: a trial release could be either "alpha", "beta",
"release candidate", "unstable", "testing", or "developer release".

=head2 Underscores

TODO

=head1 WHY?

C<version> is an official Perl module for declare and compare versions, it is recommended by
C<Task::Kensho> and used by Perl itself (C<package Assa v1.2.3;> automatically assigns C<$VERSION>
variable an object of C<version> class). Unfortunately, the module does not provide any method to
bump a version.

C<Perl::Version> is another module recommended by C<Task::Kensho>. This module provides method(s)
to bump a version, e. g.:

    my $v = Perl::Version->new( 'v1.2.3' );
    $v->inc_alpha;
    "$v";   # eq 'v1.2.3_01'

I used such code with no problem… until C<version> 0.9913. C<version> 0.9913 changed interpretation
of underscore character: before C<'v1.2.3_01'> was interpreted as C<'v1.2.3.1'> (+ trial flag,
of course), starting from 0.9913 it is interpreted as C<'v1.2.301'> (+ trial flag).

I believe there were good reasons for this change (e. g. current C<version> behavior matches Perl
behavior and so reduces the mess), but this change breaks C<Perl::Version> as well as my code
because

    version->parse( 'v1.2.3_01' ) < 'v1.2.4'

was true before, is false now.

Thus, C<Perl::Version> is broken and it is not clear when and I<how> it will be fixed. But

=over

=item 1

I want a method to bump a version, and want it now.

=item 2

I want a method to represent trial versions, and want it is compatible with C<version> either
pre-0.9913 or post-0.9912 (i. e. >= 0.77).

=item 3

I want these methods to work with dotted versions, decimal versions are out of my interest.

=back

(BTW: Requirement #2 effectively means that new method should not rely on underscores.)

C<Version::Dotted> fulfills these requirements.

=for comment ---------------------------------------------------------------------------------------

=for comment ---------------------------------------------------------------------------------------

=for comment ---------------------------------------------------------------------------------------

=for comment ---------------------------------------------------------------------------------------

=for comment ---------------------------------------------------------------------------------------

=for comment ---------------------------------------------------------------------------------------

=for comment ---------------------------------------------------------------------------------------

=head1 SEE ALSO

=over 4

=item L<version>

Parent class. It provides most of functionality, can work with decimal versions, but does not
provide any modifiers. Release status depends on presence of underscore character in version.

=item L<Perl::Version>

An alternative to C<version>. It works with both decimal and dotted versions, provides modification
operations. Release status depends on presence of underscore character in version.

=item L<Version::Next>

It provides authoring time subroutine to "increment module version numbers simply and correctly",
works with both dotted and decimal versions, but it "no longer supports dotted-decimals with alpha
elements".

=item L<SemVer>

It implements L<Semantic Versioning 1.0.0|http://semver.org/spec/v1.0.0.html> with no changes (?).
C<SemVer> allows alphanumeric pre-release versions like C<'1.2.3-alpha1'> and orders them properly:
1.2.3-alpha < 1.2.3-beta < 1.2.3. However, C<SemVer> is not I<authoring time> tool, it should be
used in runtime also to provide correct ordering: C<version> does not recognize properly
pre-release alphanumeric versions.

=item L<Version::Dotted::Semantic>

Subclass implementing adaptation of Semantic Versioning, part of this distribution.

=item L<Version::Dotted::Odd>

Subclass implementing odd/even versioning scheme, part of this distribution.

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
