# Before `make install' is performed this script should be runnable withstatistic.pl --ngram 3 --precision 10 tmi3 test-3-tmi3.out $TESTFILE
# `make test'.

##################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..30\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::NSP::Measures::2D::MI::tmi;
$loaded = 1;
print "ok 1\n";
print "ok 2\n";

######################### End of black magic.

############ Computing TMI value for some count values.

my @bigram_count = (10, 20, 20,60);

$tmi_value = calculateStatistic(n11 => 10,
                                    n1p => 20,
                                    np1 => 20,
                                    npp => 60);
$err = getErrorCode();
if($err)
{
    print "not ok 3\n";
}
elsif($tmi_value >= 0.044 && $tmi_value <= 0.045)
{
    print "ok 3\n";
}
else
{
    print "not ok 3\n";
}
############Error Code check for missing values

%count_values = (n1p => 20,
                 np1 => 20,
                 npp => 60);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 200)
{
  print "ok 4\n";
}
else
{
  print"not ok 4\n";
}

############Error Code check for missing values

%count_values = (n11 =>10,
                 np1 => 20,
                 npp => 60);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 200)
{
  print "ok 5\n";
}
else
{
  print"not ok 5\n";
}
############Error Code check for missing values

%count_values = (n11=>10,
                 n1p => 20,
                 np1 => 20);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 200)
{
  print "ok 6\n";
}
else
{
  print"not ok 6\n";
}
############Error Code check for -ve values

%count_values = (n11 => -10,
                 n1p => 20,
                 np1 => 20,
                 npp => 60);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 201)
{
  print "ok 7\n";
}
else
{
  print"not ok 7\n";
}

############Error Code check for -ve values

%count_values = (n11 => 10,
                 n1p => -20,
                 np1 => 20,
                 npp => 60);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 204)
{
  print "ok 8\n";
}
else
{
  print"not ok 8\n";
}

############Error Code check for -ve values

%count_values = (n11 => 10,
                 n1p => 20,
                 np1 => 20,
                 npp => -60);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 204)
{
  print "ok 9\n";
}
else
{
  print"not ok 9\n";
}

############Error Code check invalid values

%count_values = (n11 => 80,
                 n1p => 20,
                 np1 => 20,
                 npp => 60);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 202)
{
  print "ok 10\n";
}
else
{
  print"not ok 10\n";
}

############Error Code check invalid values

%count_values = (n11 => 30,
                 n1p => 20,
                 np1 => 20,
                 npp => 60);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 202)
{
  print "ok 11\n";
}
else
{
  print"not ok 11\n";
}


############Error Code check invalid values

%count_values = (n11 => 10,
                 n1p => 70,
                 np1 => 20,
                 npp => 60);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 203)
{
  print "ok 12\n";
}
else
{
  print"not ok 12\n";
  print $err;
}

############## Checking Error code for -ve observed frequency

$value = calculateStatistic(n11 => 10,
                                    n1p => 20,
                                    np1 => 11,
                                    npp => 20);
$err = getErrorCode();
if($err==201)
{
    print "ok 13\n";
}
else
{
    print "not ok 13\n";
}

############## Checking measure value for a contingency table with a zero observed value

$value = calculateStatistic(n11 => 10,
                                    n1p => 20,
                                    np1 => 20,
                                    npp => 30);
$err = getErrorCode();
if($value<=0.25163 and $value >= 0.25162)
{
    print "ok 14\n";
}
else
{
    print "not ok 14\n";
}

############## Checking measure value for actual bigram data

my $n11; my $n1p; my $np1; my $npp;

$npp = 567835;
$n11 = 3972;
$n1p = 23189;
$np1 = 22641;

$value = calculateStatistic(n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.00811664023 and $value > 0.008116640229)
{
    print "ok 15\n";
}
else
{
    print "not ok 15\n";
}

##############

$npp = 567835;
$n11 = 2298;
$n1p = 4624;
$np1 = 8677;
$value = calculateStatistic(n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.017176257 and $value > 0.01717625692)
{
    print "ok 16\n";
}
else
{
    print "not ok 16\n";
}

##############

$npp = 8293549;
$n11 = 44796;
$n1p = 179966;
$np1 = 433831;
$value = calculateStatistic(n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.006966758 and $value > 0.0069667579)
{
    print "ok 17\n";
}
else
{
    print "not ok 17\n";
}

##############

$npp = 8293549;
$n11 = 40666;
$n1p = 432943;
$np1 = 433831;
$value = calculateStatistic( n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.0011497524277 and $value > 0.0011497524276)
{
    print "ok 18\n";
}
else
{
    print "not ok 18\n";
}

##############

$npp = 8293549;
$n11 = 37397;
$n1p = 143010;
$np1 = 433831;
$value = calculateStatistic(n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.00608380564 and $value > 0.00608380563)
{
    print "ok 19\n";
}
else
{
    print "not ok 19\n";
}

##############

$npp = 8293549;
$n11 = 32660;
$n1p = 454949;
$np1 = 433831;
$value = calculateStatistic(n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.000290487 and $value > 0.0002904869)
{
    print "ok 20\n";
}
else
{
    print "not ok 20\n";
}

##############

$npp = 8293549;
$n11 = 25919;
$n1p = 454949;
$np1 = 169091;
$value = calculateStatistic(n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.00195207067 and $value > 0.001952070669)
{
    print "ok 21\n";
}
else
{
    print "not ok 21\n";
}

##############

$npp = 8293549;
$n11 = 17042;
$n1p = 454949;
$np1 = 185958;
$value = calculateStatistic(n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.0003645729839 and $value > 0.00036457298389)
{
    print "ok 22\n";
}
else
{
    print "not ok 22\n";
}

##############

$npp = 8293549;
$n11 = 16862;
$n1p = 186141;
$np1 = 433831;
$value = calculateStatistic(n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.0004077190656 and $value > 0.0004077190655)
{
    print "ok 23\n";
}
else
{
    print "not ok 23\n";
}

##############

$npp = 8293549;
$n11 = 16115;
$n1p = 52569;
$np1 = 432944;
$value = calculateStatistic(n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.0030195810652 and $value > 0.0030195810651)
{
    print "ok 24\n";
}
else
{
    print "not ok 24\n";
}

##############

$npp = 8293549;
$n11 = 16089;
$n1p = 432943;
$np1 = 34837;
$value = calculateStatistic(n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.0042994816155 and $value > 0.00429948161549)
{
    print "ok 25\n";
}
else
{
    print "not ok 25\n";
}

##############

$npp = 8293549;
$n11 = 15800;
$n1p = 432943;
$np1 = 432944;
$value = calculateStatistic(n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.0002191746535 and $value > 0.00021917465349)
{
    print "ok 26\n";
}
else
{
    print "not ok 26\n";
}

##############

$npp = 8293549;
$n11 = 15459;
$n1p = 54930;
$np1 = 433831;
$value = calculateStatistic(n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.0026587988023 and $value > 0.0026587988022)
{
    print "ok 27\n";
}
else
{
    print "not ok 27\n";
}

##############

$npp = 8293549;
$n11 = 14206;
$n1p = 454949;
$np1 = 52569;
$value = calculateStatistic(n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.0022409841686 and $value > 0.0022409841685)
{
    print "ok 28\n";
}
else
{
    print "not ok 28\n";
}

##############

$npp = 8293549;
$n11 = 14075;
$n1p = 432943;
$np1 = 59565;
$value = calculateStatistic(n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.00201392868 and $value > 0.00201392867)
{
    print "ok 29\n";
}
else
{
    print "not ok 29\n";
}

##############

$npp = 8293549;
$n11 = 14070;
$n1p = 432943;
$np1 = 34669;
$value = calculateStatistic(n11 => $n11,
                                    n1p => $n1p,
                                    np1 => $np1,
                                    npp => $npp);
$err = getErrorCode();
if($value < 0.003378394906 and $value > 0.003378394905)
{
    print "ok 30\n";
}
else
{
    print "not ok 30\n";
}

##############