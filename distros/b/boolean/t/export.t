use Test::More tests => 4 * 6;
use strict;
# use warnings;
use lib 'lib';

package None;
use boolean();

package Default;
use boolean;

package All;
use boolean ':all';

package Test;
use boolean ':test';

package main;

use boolean;

my @functions = qw(true false boolean isTrue isFalse isBoolean);
my @exports = qw(None Default All Test);
my %exported = (
    None    => [false, false, false, false, false, false],
    Default => [true, true, true, false, false, false],
    All     => [true, true, true, true, true, true],
    Test    => [false, false, false, true, true, true],
);

for my $export (@exports) {
    my $tag = ":" . lc($export);
    for (my $i = 0; $i < @functions; $i++) {
        my $function = $functions[$i];
        my $exported = $exported{$export}->[$i];
        my $defined = defined(&{$export . "::" . $function}) ? 1 : 0;
        my $test = $exported == $defined;
        ok $test,
            $tag .
            ($exported ? " imports " : " does not import ") .
            $function;
    }
}
