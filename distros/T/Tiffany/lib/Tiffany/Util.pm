package Tiffany::Util;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/slurp/;

sub slurp {
    my $stuff = shift;
    return ${$stuff} if ref $stuff;

    open my $fh, '<', $stuff or do {
        die "Cannot open file '@{[ $stuff ]}': $!";
    };
    do { local $/; <$fh> };
}

1;
