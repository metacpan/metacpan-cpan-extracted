# Prefer numeric version for backwards compatibility
BEGIN { require 5.010_001 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

package Tie::Hash::MultiValueOpts;

$Tie::Hash::MultiValueOpts::VERSION = 'v1.0.2';

use Tie::Hash ();
use parent -norequire, 'Tie::StdHash';

sub STORE {
  my ( $self, $key, $value ) = @_;

  if ( my $current_value = $self->{ $key } ) {
    if ( 'ARRAY' eq ref $current_value ) {
      push @{ $current_value }, $value;
      return $current_value
    }
  }
  $self->SUPER::STORE( $key, $value )
}

1
