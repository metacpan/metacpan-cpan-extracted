##################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::NSP::Measures::2D::CHI::x2;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

############ check fix for divide by zero error found in 1.01

# this table represents the case where there are 10 bigrams in
# the sample, and they are all the same bigram. The 2x3 table
# would look like this:
#
# 10 0 | 10
#  0 0 | 0
# ------
# 10 0   10

$x2_value = calculateStatistic(n11 => 10,
                                    n1p => 10,
                                    np1 => 10,
                                    npp => 10);
$err = getErrorCode();
if($err)
{
    print "not ok 2 $err\n";
}
elsif($x2_value == 0)
{
    print "ok 2\n";
}
else
{
    print "not ok 2 $x2_value\n";
}

############ check fix for divide by zero error found in 1.01

# this table represents the case where there are 15 bigrams in
# the sample, and they are all from 2 bigrams that share one
# word. The 2x2 table would look like this:
#
# 9  0  | 9
# 6  0  | 6
# -------
# 15 0   15

$x2_value = calculateStatistic(n11 => 9,
                                    n1p => 9,
                                    np1 => 15,
                                    npp => 15);
$err = getErrorCode();
if($err)
{
    print "not ok 3 $err\n";
}
elsif($x2_value == 0)
{
    print "ok 3\n";
}
else
{
    print "not ok 3 $x2_value\n";
}

# this table represents the case where there is a zero observed
# value - this did not cause any problems before, and the test case
# is added to make sure that it doesn't in future. The 2x3 table
# looks like this
#
# 9  0  | 9
# 6  6  | 12
# -------
# 15 6   21

$x2_value = calculateStatistic(n11 => 9,
                                    n1p => 9,
                                    np1 => 15,
                                    npp => 21);
$err = getErrorCode();
if($err)
{
    print "not ok 4 $err\n";
}
elsif($x2_value >= 6.29 && $x2_value <= 6.30)
{
    print "ok 4\n";
}
else
{
    print "not ok 4 $x2_value\n";
}


