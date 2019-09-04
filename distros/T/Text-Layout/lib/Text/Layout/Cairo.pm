#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Text::Layout::Cairo;

sub init {
    my ( $pkg, @args ) = @_;
    bless {} => $pkg;
}

1;
