##################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..29\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::NSP::Measures::2D::MI::ll;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

############ Computing ll value for some count values.

my @bigram_count = (10, 20, 20,60);

$ll_value = calculateStatistic(n11 => 10,
                                    n1p => 20,
                                    np1 => 20,
                                    npp => 60);
$err = getErrorCode();
if($err)
{
    print "not ok 2\n";
}
elsif($ll_value >= 3.66900140 && $ll_value <= 3.66900141)
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
if($value<=10.464963 and $value >= 10.464962)
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
if($value < 6389.3092775 and $value > 6389.3092774)
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
if($value < 13520.916861 and $value > 13520.91686)
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
if($value < 80098.9079551 and $value > 80098.9079550)
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
if($value < 13219.048831 and $value > 13219.048830)
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
if($value < 69947.339789 and $value > 69947.339788)
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
if($value < 3339.81521 and $value > 3339.8152)
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
if($value < 22443.542519 and $value > 22443.542518)
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
if($value < 4191.60504517 and $value > 4191.60504516)
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
if($value < 4687.66849925 and $value > 4687.66849924)
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
if($value < 34717.03002199 and $value > 34717.03002198)
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
if($value < 49432.430891 and $value > 49432.4308909)
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
if($value < 2519.91679018 and $value > 2519.91679017)
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
if($value < 30569.0080341 and $value > 30569.0080340)
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

## test condition relaxed due to failures on 64 bit systems
## if($value < 25765.2677567 and $value > 25765.2677566)

if($value < 25765.2677570 and $value > 25765.2677560)
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
if($value < 23154.74263384 and $value > 23154.742633839)
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

## relaxed due to failures on 64 bit systems
## if($value < 38842.420466473 and $value > 38842.42046647)

if($value < 38842.420466480 and $value > 38842.42046640)
{
    print "ok 29\n";
}
else
{
    print "not ok 29\n";
}


##############
