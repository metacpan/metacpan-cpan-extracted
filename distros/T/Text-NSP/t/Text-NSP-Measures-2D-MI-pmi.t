# Before `make install' is performed this script should be runnable with
# `make test'.

##################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..29\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::NSP::Measures::2D::MI::pmi;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

############ Computing PMI value for some count values.

my @bigram_count = (10, 20, 20,60);

$value = calculateStatistic(n11 => 10,
                                    n1p => 20,
                                    np1 => 20,
                                    npp => 60);
$err = getErrorCode();
if($err)
{
    print "not ok 2\n";
}
elsif($value >= 0.58 && $value <= 0.59)
{
    print "ok 2\n";
}
else
{
    print "not ok 2\n";
}

############Error Code check for missing values

%count_values = (n1p => 20,
                 np1 => 20,
                 npp => 60);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 200)
{
  print "ok 3\n";
}
else
{
  print"not ok 3\n";
}

############Error Code check for missing values

%count_values = (n11 =>10,
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

%count_values = (n11=>10,
                 n1p => 20,
                 np1 => 20);

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
############Error Code check for -ve values

%count_values = (n11 => -10,
                 n1p => 20,
                 np1 => 20,
                 npp => 60);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 201)
{
  print "ok 6\n";
}
else
{
  print"not ok 6\n";
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
  print "ok 7\n";
}
else
{
  print"not ok 7\n";
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
  print "ok 8\n";
}
else
{
  print"not ok 8\n";
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
  print "ok 9\n";
}
else
{
  print"not ok 9\n";
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
  print "ok 10\n";
}
else
{
  print"not ok 10\n";
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
  print "ok 11\n";
}
else
{
  print"not ok 11\n";
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
    print "ok 12\n";
}
else
{
    print "not ok 12\n";
}

############## Checking measure value for a contingency table with a zero observed value

$value = calculateStatistic(n11 => 10,
                                    n1p => 20,
                                    np1 => 20,
                                    npp => 30);
$err = getErrorCode();
if($value<=-0.41503 and $value >= -0.41504)
{
    print "ok 13\n";
}
else
{
    print "not ok 13\n";
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
if($value < 2.10296 and $value > 2.102959)
{
    print "ok 14\n";
}
else
{
    print "not ok 14\n";
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
if($value < 5.02336904 and $value > 5.02336903)
{
    print "ok 15\n";
}
else
{
    print "not ok 15\n";
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
if($value < 2.250502 and $value > 2.2505019)
{
    print "ok 16\n";
}
else
{
    print "not ok 16\n";
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
if($value < 0.844502445 and $value > 0.844502444)
{
    print "ok 17\n";
}
else
{
    print "not ok 17\n";
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
if($value < 2.32166296 and $value > 2.321662959)
{
    print "ok 18\n";
}
else
{
    print "not ok 18\n";
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
if($value < 0.456676414 and $value > 0.456676413)
{
    print "ok 19\n";
}
else
{
    print "not ok 19\n";
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
if($value < 1.48249496 and $value > 1.48249495)
{
    print "ok 20\n";
}
else
{
    print "not ok 20\n";
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
if($value < 0.74040261 and $value > 0.74040260)
{
    print "ok 21\n";
}
else
{
    print "not ok 21\n";
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
if($value < 0.79223626 and $value > 0.79223625)
{
    print "ok 22\n";
}
else
{
    print "not ok 22\n";
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
if($value < 2.55392916 and $value > 2.553929159)
{
    print "ok 23\n";
}
else
{
    print "not ok 23\n";
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
if($value < 3.145194863 and $value > 3.145194862)
{
    print "ok 24\n";
}
else
{
    print "not ok 24\n";
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
if($value < -0.5164433705 and $value > -0.5164433707)
{
    print "ok 25\n";
}
else
{
    print "not ok 25\n";
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
if($value < 2.4276372511 and $value > 2.4276372510)
{
    print "ok 26\n";
}
else
{
    print "not ok 26\n";
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
if($value < 2.3005009626 and $value > 2.3005009625)
{
    print "ok 27\n";
}
else
{
    print "not ok 27\n";
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
if($value < 2.1784106554 and $value > 2.1784106553)
{
    print "ok 28\n";
}
else
{
    print "not ok 28\n";
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
if($value < 2.9587167 and $value > 2.95871669)
{
    print "ok 29\n";
}
else
{
    print "not ok 29\n";
}

##############
