##################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::NSP::Measures::3D::MI::ll;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

############ check fix for divide by zero error found in 1.01

# this table represents the case where there are 10 bigrams in
# the sample, and they are all the same trigram.

$ll_value = calculateStatistic( n111=>10,
                                n1pp=>10,
                                np1p=>10,
                                npp1=>10,
                                n11p=>10,
                                n1p1=>10,
                                np11=>10,
                                nppp=>10);
$err = getErrorCode();
if($err)
{
    print "not ok 2 $err\n";
}
elsif($ll_value == 0)
{
    print "ok 2\n";
}
else
{
    print "not ok 2 $ll_value\n";
}

############ check fix for divide by zero error found in 1.01

# this table represents the case where there are 15 trigrams in
# the sample, and they are all from 3 trigrams that share one
# word.

undef $ll_value;

$ll_value = calculateStatistic( n111=>5,
                                n1pp=>13,
                                np1p=>15,
                                npp1=>23,
                                n11p=>5,
                                n1p1=>13,
                                np11=>15,
                                nppp=>23);


$err = getErrorCode();
if($err)
{
    print "not ok 3 $err\n";
}
elsif($ll_value >= 12.39 && $ll_value <= 12.40)
{
    print "ok 3\n";
}
else
{
    print "not ok 3 $ll_value\n";
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

$ll_value = calculateStatistic( n111=>2,
                                n1pp=>338,
                                np1p=>134,
                                npp1=>463,
                                n11p=>3,
                                n1p1=>2,
                                np11=>27,
                                nppp=>4987);
$err = getErrorCode();
if($err)
{
    print "not ok 4 $err\n";
}
elsif($ll_value >= 89.59 && $ll_value <= 89.60)
{
    print "ok 4\n";
}
else
{
    print "not ok 4 $ll_value\n";
}
