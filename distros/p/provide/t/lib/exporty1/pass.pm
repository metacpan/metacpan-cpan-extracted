use strict;
use warnings;
package exporty1::pass;
use base qw(Exporter);

our @EXPORT    = qw(moonset craving);
our @EXPORT_OK = qw(counsel coconut);

sub moonset { __PACKAGE__ . '::moonset' }
sub craving { __PACKAGE__ . '::craving' }
sub counsel { __PACKAGE__ . '::counsel' }
sub coconut { __PACKAGE__ . '::coconut' }

1;
