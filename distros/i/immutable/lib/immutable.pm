use strict; use warnings;
package immutable;
our $VERSION = '0.0.4';

sub import {
    die "Currently invalid to 'use immutable;'. Try 'use immutable::0;'.";
}
