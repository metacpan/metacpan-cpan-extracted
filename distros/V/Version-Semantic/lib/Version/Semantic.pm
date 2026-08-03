# Prefer numeric version for backwards compatibility
BEGIN { require 5.010000 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

#<<<
package Version::Semantic;
BEGIN {
our $VERSION = 'v2.0.0';
}
#>>>

use overload '<=>' => 'compare_to', '""' => 'to_string';

use PerlX::Maybe ();

sub _croakf ( $@ );

my $prefix_re = qr/v/;

# <identifier characters>
my $id_re = qr/(?: [0-9] | [a-zA-Z-] )+/x;

# <numeric identifier> (ok)
my $num_id_re = qr/0 | [1-9] | [1-9] [0-9]+/x;

# <alphanumeric identifier>
my $alnum_id_re = qr/[a-zA-Z-] | [a-zA-Z-] $id_re | $id_re [a-zA-Z-] | $id_re [a-zA-Z-] $id_re/x;

# <build identifier>
#my $build_id_re = qr/[0-9a-zA-Z-]+/;
my $build_id_re = qr/$alnum_id_re | [0-9]+/x;
# <build> (ok)
my $build_re = qr/$build_id_re (?: \. $build_id_re )*/x;

# <pre-release identifier>
#my $pre_release_id_re = qr/$num_id_re | [0-9]* [a-zA-Z-] [0-9a-zA-Z-]*/x;
my $pre_release_id_re = qr/$num_id_re | $alnum_id_re/x;
# <pre-release> (ok)
my $pre_release_re = qr/$pre_release_id_re (?: \. $pre_release_id_re )*/x;

# Use BNF terminology
# https://semver.org/spec/v2.0.0.html#backusnaur-form-grammar-for-valid-semver-versions
sub prefix       { shift->{ prefix } }
sub major        { shift->{ major } }
sub minor        { shift->{ minor } }
sub patch        { shift->{ patch } }
sub version_core { shift->{ version_core } }
sub pre_release  { shift->{ pre_release } }
sub build        { shift->{ build } }

sub has_prefix      { defined shift->{ prefix } }
sub has_pre_release { defined shift->{ pre_release } }
sub has_build       { defined shift->{ build } }

{
  ## no critic ( ProhibitComplexRegexes )
  # On purpose use "build" (the BNF symbol name) instead of "buildmetadata" as
  # the name of the last named capture group
  # <valid semver> (ok)
  my $semver_re = qr/
    (?<prefix> $prefix_re)?
    (?<major> $num_id_re) \. (?<minor> $num_id_re) \. (?<patch> $num_id_re)
    (?: -  (?<pre_release> $pre_release_re) )?
    (?: \+ (?<build> $build_re) )?
  /x;
  sub semver_re { $semver_re }

  # Constructor as factory method
  sub parse {
    my $options = ( ref $_[ -1 ] eq 'HASH' ) ? pop : {};
    my ( $class, $version ) = @_;
    $version //= '';

    unless ( $version =~ m/\A$semver_re\z/ ) {
      _croakf "Version '%s' is not a semantic version", $version if $options->{ fatal };
      return
    }

    $class->new( %+ )
  }
}

{
  my %attrs = (
    prefix      => $prefix_re,
    major       => $num_id_re,
    minor       => $num_id_re,
    patch       => $num_id_re,
    pre_release => $pre_release_re,
    build       => $build_re
  );

  sub new {
    my $invocant = shift;
    my %args;

    # Validate args
    {
      use warnings FATAL => qw( misc uninitialized );
      %args = @_
    };
    foreach ( keys %args ) {
      unless ( defined $args{ $_ } ) {
        delete $args{ $_ };
        next
      }
      _croakf "Unknown attribute name '%s'", $_
        unless exists $attrs{ $_ };
      _croakf "Attribute '%s' has invalid value '%s'", $_, $args{ $_ }
        unless $args{ $_ } =~ m/\A $attrs{ $_ } \z/x
    }

    my $class;
    if ( $class = ref $invocant ) {
      # Shallow copy
      %args = ( %$invocant, %args )
    } else {
      $class = $invocant;
    }

    # Don't move this attribute checking
    exists $args{ $_ } or _croakf "Required attribute '%s' not set", $_
      foreach qw( major minor patch );

    bless { %args,
      version_core => ( $args{ prefix } // '' ) . join( '.', map { $args{ $_ } } qw( major minor patch ) ) } => $class
  }
}

{
  my $trial_pre_release = qr/\A ( TRIAL ) ( [0-9]* ) \z/x;

  sub increment {
    # Obvious strategies are major|minor|patch
    my ( $self, $strategy, $pre_release ) = @_;
    $strategy //= 'patch';

    if ( $strategy eq 'trial' ) {
      if ( $self->has_pre_release ) {
        if ( my ( $string, $number ) = $self->pre_release =~ $trial_pre_release ) {
          return $self->new( pre_release => $string . ( ( $number eq '' ? 0 : $number ) + 1 ) )
        } else {
          _croakf "Pre-release extension '%s' does not match '%s'", $self->pre_release, $trial_pre_release
        }
      } else {
        _croakf "Cannot apply '%s' version incrementation strategy to non pre-release version '%s'", $strategy, $self
      }
    }
    return $self->new( patch => $self->patch + 1, PerlX::Maybe::maybe pre_release => $pre_release )
      if $strategy eq 'patch';
    return $self->new( minor => $self->minor + 1, patch => 0, PerlX::Maybe::maybe pre_release => $pre_release )
      if $strategy eq 'minor';
    return $self->new( major => $self->major + 1, minor => 0, patch => 0, PerlX::Maybe::maybe pre_release => $pre_release )
      if $strategy eq 'major';

    _croakf "Version incrementation strategy '%s' is not implemented", $strategy
  }
}

# https://semver.org/spec/v2.0.0.html#spec-item-11
sub compare_to {
  my ( $self, $other ) = @_;

  # 11.2
  for ( qw( major minor patch ) ) {
    return $self->$_ <=> $other->$_ if $self->$_ != $other->$_
  }
  $self->_compare_pre_release( $other )
}

sub to_string {
  my ( $self ) = @_;

  my $string = $self->version_core;
  $string .= '-' . $self->pre_release if $self->has_pre_release;
  $string .= '+' . $self->build       if $self->has_build;
  $string
}

sub _compare_pre_release {
  my ( $self, $other ) = @_;

  # Split pre-release into list of dot separated identifiers
  my @a = $self->has_pre_release  ? split /\./, $self->pre_release  : ();
  my @b = $other->has_pre_release ? split /\./, $other->pre_release : ();

  # 11.3
  if ( @a ) {
    return -1 if not @b
  } else {
    return ( @b ? 1 : 0 )
  }

  # 11.4
  my $len = @a < @b ? @a : @b;
  for ( my $i = 0 ; $i < $len ; $i++ ) {
    my $ai = $a[ $i ];
    my $bi = $b[ $i ];

    my $ai_is_num = $ai =~ m/\A $num_id_re \z/x;
    my $bi_is_num = $bi =~ m/\A $num_id_re \z/x;

    # 11.4.1
    if ( $ai_is_num and $bi_is_num ) {
      my $sign = $ai <=> $bi;
      return $sign if $sign != 0
      # 11.4.3
    } elsif ( $ai_is_num and not $bi_is_num ) {
      return -1
      # 11.4.3
    } elsif ( not $ai_is_num and $bi_is_num ) {
      return 1
    } else {
      my $sign = $ai cmp $bi;
      return $sign if $sign != 0
    }
  }

  # 11.4.4
  @a <=> @b
}

sub _croakf ( $@ ) {
  require Carp;
  @_ = ( ( @_ == 1 ? shift : sprintf shift, @_ ) . ', stopped' );
  goto &Carp::croak
}

1
