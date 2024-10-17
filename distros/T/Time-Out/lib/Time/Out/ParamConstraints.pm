use strict;
use warnings;

package Time::Out::ParamConstraints;

# keeping the following $VERSION declaration on a single line is important
#<<<
use version 0.9915; our $VERSION = version->declare( '1.0.0' );
#>>>

use Exporter     qw( import );
use Scalar::Util qw( blessed looks_like_number reftype );

our @EXPORT_OK = qw( assert_NonNegativeNumber assert_CodeRef );

sub _is_CodeRef ( $ );
sub _is_String ( $ );
sub _croakf ( $@ );

sub assert_NonNegativeNumber( $ ) {
  my ( $value ) = @_;

  _is_String $value
    && looks_like_number $value
    && $value !~ /\A (?: Inf (?: inity )? | NaN ) \z/xi
    && $value >= 0 ? return $value : _croakf 'value is not a non-negative number';
}

sub assert_CodeRef( $ ) {
  my ( $value ) = @_;

  _is_CodeRef $value ? return $value : _croakf 'value is not a code reference';
}

sub _is_CodeRef( $ ) {
  my ( $value ) = @_;

  return !defined blessed $value && ref $value eq 'CODE';
}

sub _is_String( $ ) {
  my ( $value ) = @_;

  return defined $value && reftype \$value eq 'SCALAR';
}

sub _croakf( $@ ) {
  # load Carp lazily
  require Carp;
  @_ = ( ( @_ == 1 ? shift : sprintf shift, @_ ) . ', stopped' );
  goto &Carp::croak;
}

1;
