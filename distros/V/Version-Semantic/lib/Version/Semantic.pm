# Prefer numeric version for backwards compatibility
BEGIN { require 5.010_000 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

package Version::Semantic;

$Version::Semantic::VERSION = 'v1.0.1';

use overload '""' => 'to_string', '<=>' => 'compare_to';

sub _croakf ( $@ );

# On purpose use "build" (the BNF symbol name) instead of "buildmetadata" as
# the name of the last named capture group
sub _SEM_VER_REG_EX () {
  ## no critic ( ProhibitComplexRegexes )
  qr/
    \A
    (?<prefix> v )?
    (?<major> 0 | [1-9]\d* ) \. (?<minor> 0 | [1-9]\d* ) \.(?<patch> 0 | [1-9]\d* )
    (?: -  (?<pre_release> (?: 0 | [1-9]\d* | \d*[a-zA-Z-][0-9a-zA-Z-]* ) (?: \. (?: 0 | [1-9]\d* | \d*[a-zA-Z-][0-9a-zA-Z-]* ) )* ) )?
    (?: \+ (?<build> [0-9a-zA-Z-]+ (?: \. [0-9a-zA-Z-]+ )* ) )?
    \z
  /x
}

# Use BNF terminology
# https://semver.org/spec/v2.0.0.html#backusnaur-form-grammar-for-valid-semver-versions
sub major        { shift->{ major } }
sub minor        { shift->{ minor } }
sub patch        { shift->{ patch } }
sub version_core { shift->{ version_core } }
sub pre_release  { shift->{ pre_release } }
sub build        { shift->{ build } }

sub has_pre_release { defined shift->{ pre_release } }
sub has_build       { defined shift->{ build } }

# Constructor as factory method
sub parse {
  my ( $class, $version ) = @_;

  $version =~ m/${ \( _SEM_VER_REG_EX ) }/x
    or _croakf "Version '%s' is not a semantic version", $version;

  bless { %+, version_core => ( $+{ prefix } // '' ) . join( '.', map { $+{ $_ } } qw( major minor patch ) ) }, $class
}

sub to_string {
  my ( $self ) = @_;

  my $string = $self->version_core;
  $string .= '-' . $self->pre_release if $self->has_pre_release;
  $string .= '+' . $self->build       if $self->has_build;
  $string
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

    my $ai_is_num = $ai =~ m/\A (?: 0 | [1-9]\d* ) \z/x;
    my $bi_is_num = $bi =~ m/\A (?: 0 | [1-9]\d* ) \z/x;

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
