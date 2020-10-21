#!/usr/bin/env perl

use strict;
use warnings;

use Zodiac::Angle;
use Unicode::UTF8 qw(encode_utf8);

# Object.
my $obj = Zodiac::Angle->new;

if (@ARGV < 1) {
        print STDERR "Usage: $0 angle\n";
        exit 1;
}
my $angle = $ARGV[0];

my $zodiac_angle = Zodiac::Angle->new->angle2zodiac($angle, {
        'minute' => 1,
        'second' => 1,
        'second_round' => 4,
        'sign_type' => 'ascii',
});

# Print out.
print 'Angle: '.$angle."\n";
print 'Zodiac angle: '.encode_utf8($zodiac_angle)."\n";

# Output without arguments:
# Usage: __SCRIPT__ angle

# Output with '0.5' argument:
# Angle: 0.5
# Zodiac angle: 0° ar 30'0.0000''