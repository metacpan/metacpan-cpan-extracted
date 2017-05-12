package CleaneeTarget;
use strict;
use warnings;

sub AWAY    { 23 };
sub IGNORED { 27 };

use CleaneeBridge;

sub NOTAWAY { 17 };

sub x_foo { 'XFOO' }
sub x_bar { 'XBAR' }
sub x_baz { 'XBAZ' }

use CleaneeBridgeExplicit;

sub d_foo { 7 }
sub d_bar { 8 }
sub d_baz { 9 }

sub summary { [AWAY, IGNORED, NOTAWAY, x_foo, x_bar, x_baz, d_foo, d_bar, d_baz] }

use CleaneeBridgeDirect;

1;
