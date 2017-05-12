# Before `make install' is performed this script should be runnable with
# `make test'.

##################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..18\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::NSP::Measures::3D::MI::ps;
$loaded = 1;
print "ok 1\n";
print "ok 2\n";

######################### End of black magic.

############ Computing PS value for some count values.

$ps_value = calculateStatistic(  n111=>10,
                                        n1pp=>40,
                                        np1p=>45,
                                        npp1=>42,
                                        n11p=>20,
                                        n1p1=>23,
                                        np11=>21,
                                        nppp=>100);

$err = getErrorCode();
if($err)
{
    print "not ok 3\n";
}
elsif($ps_value <= -7.20286097197 && $ps_value >= -7.20286097198)
{
    print "ok 3\n";
}
else
{
    print "not ok 3\n";
}

############Error Code check for missing values

%count_values = ( n1pp=>40,
                  np1p=>45,
                  npp1=>42,
                  n11p=>20,
                  n1p1=>23,
                  np11=>21,
                  nppp=>100);

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

%count_values = ( n111=>10,
                  np1p=>45,
                  npp1=>42,
                  n11p=>20,
                  n1p1=>23,
                  np11=>21,
                  nppp=>100);
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

%count_values = ( n111=>10,
                  n1pp=>40,
                  npp1=>42,
                  n11p=>20,
                  n1p1=>23,
                  np11=>21,
                  nppp=>100);

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

############Error Code check for missing values

%count_values = ( n111=>10,
                  n1pp=>40,
                  np1p=>45,
                  n11p=>20,
                  n1p1=>23,
                  np11=>21,
                  nppp=>100);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 200)
{
  print "ok 7\n";
}
else
{
  print"not ok 7\n";
}

############Error Code check for missing values

%count_values = ( n111=>10,
                  n1pp=>40,
                  np1p=>45,
                  npp1=>42,
                  n1p1=>23,
                  np11=>21,
                  nppp=>100);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 200)
{
  print "ok 8\n";
}
else
{
  print"not ok 8\n";
}


############Error Code check for missing values

%count_values = ( n111=>10,
                  n1pp=>40,
                  np1p=>45,
                  npp1=>42,
                  n11p=>20,
                  np11=>21,
                  nppp=>100);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 200)
{
  print "ok 9\n";
}
else
{
  print"not ok 9\n";
}


############Error Code check for missing values

%count_values = ( n111=>10,
                  n1pp=>40,
                  np1p=>45,
                  npp1=>42,
                  n11p=>20,
                  n1p1=>23,
                  nppp=>100);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 200)
{
  print "ok 10\n";
}
else
{
  print"not ok 10\n";
}

############Error Code check for missing values

%count_values = ( n111=>10,
                  n1pp=>40,
                  np1p=>45,
                  npp1=>42,
                  n11p=>20,
                  n1p1=>23,
                  np11=>21);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 200)
{
  print "ok 11\n";
}
else
{
  print"not ok 11\n";
}


############Error Code check for -ve values

%count_values = ( n111=>-10,
                  n1pp=>40,
                  np1p=>45,
                  npp1=>42,
                  n11p=>20,
                  n1p1=>23,
                  np11=>21,
                  nppp=>100);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 201)
{
  print "ok 12\n";
}
else
{
  print"not ok 12\n";
}

############Error Code check for -ve values

%count_values = ( n111=>10,
                  n1pp=>-40,
                  np1p=>45,
                  npp1=>42,
                  n11p=>20,
                  n1p1=>23,
                  np11=>21,
                  nppp=>100);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 204)
{
  print "ok 13\n";
}
else
{
  print"not ok 13\n";
}


############Error Code check for -ve values

%count_values = ( n111=>10,
                  n1pp=>40,
                  np1p=>45,
                  npp1=>42,
                  n11p=>20,
                  n1p1=>23,
                  np11=>21,
                  nppp=>-100);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 200)
{
  print "ok 14\n";
}
else
{
  print"not ok 14\n";
}


############Error Code check invalid values

%count_values = ( n111=>90,
                  n1pp=>40,
                  np1p=>45,
                  npp1=>42,
                  n11p=>20,
                  n1p1=>23,
                  np11=>21,
                  nppp=>100);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 202)
{
  print "ok 15\n";
}
else
{
  print"not ok 15\n";
}


############Error Code check invalid values

%count_values = ( n111=>10,
                  n1pp=>90,
                  np1p=>45,
                  npp1=>42,
                  n11p=>20,
                  n1p1=>23,
                  np11=>21,
                  nppp=>100);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 202)
{
  print "ok 16\n";
}
else
{
  print"not ok 16\n";
}

############Error Code check invalid values

%count_values = ( n111=>10,
                  n1pp=>40,
                  np1p=>145,
                  npp1=>42,
                  n11p=>20,
                  n1p1=>23,
                  np11=>21,
                  nppp=>100);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 203)
{
  print "ok 17\n";
}
else
{
  print"not ok 17\n";
}


############## Checking Error code for -ve observed frequency

%count_values = ( n111=>10,
                  n1pp=>9,
                  np1p=>45,
                  npp1=>42,
                  n11p=>20,
                  n1p1=>23,
                  np11=>21,
                  nppp=>100);

$value = calculateStatistic(%count_values);
$err = getErrorCode();
if($err==202)
{
    print "ok 18\n";
}
else
{
    print "not ok 18\n";
}