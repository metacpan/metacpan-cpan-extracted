#!/perl -I..

use strict;
use warnings;
no warnings 'uninitialized';
print "1..14\n";

my $tn=0;
sub is
{
    my $ok = $_[0] eq $_[1]? "ok " : "not ok ";
    print $ok, ++$tn;
    if ($ok eq "not ok ")
    {
        print "\t$_[2]: expected '$_[1]', got '$_[0]'"
    }
    print "\n";
}

use Tie::Comma;

# Were all variables imported? (1)
is ref tied %comma, 'Tie::Comma' => '%comma imported';


# Basic tests (5)
my $a = 98765432;
is $comma{$a},    '98,765,432'    => 'integer format';
is $comma{$a, 2}, '98,765,432.00' => 'Two decimal places';
my $b = 1234;
is $comma{$b, undef, 9}, '    1,234' => 'padding';
is $comma{$b,     2, 9}, ' 1,234.00' => 'padding, 2dp';
is $comma{$b,     2, 4},  '1,234.00' => 'padding, 2dp, > width';

# Negative numbers, rounding (4)
my $c = -12345.67;
is $comma{$c},   '-12,345.67'  => 'negative, fractional';
is $comma{$c,1}, '-12,345.7'   => 'negative, fractional, 1dp';
is $comma{$c,0},    '-12,346'  => 'negative, fractional, 0dp';
is $comma{$c,3}, '-12,345.670' => 'negative, fractional, 3dp';

# Null inputs (2)
is $comma{+undef}, ''  => 'undefined';
is $comma{''},     ''  => 'empty string';

# Interpolation (2)
is ":$comma{$b}:", ":1,234:"  => 'interpolation';
is ":$comma{$c,2-1,3*4}:", ":   -12,345.7:"  => 'interpolation, rounding, padding';
