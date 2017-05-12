# Before `make install' is performed this script should be runnable with
# `make test'.

##################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::NSP::Measures::2D::MI::ps;
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
elsif($value >= -5.94534892 && $value <= -5.94534891)
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
