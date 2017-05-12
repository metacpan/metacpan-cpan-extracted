package
 t_undef_error;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT = qw(t_undef_error);

sub t_undef_error {
  undef() . '';
}

1;
