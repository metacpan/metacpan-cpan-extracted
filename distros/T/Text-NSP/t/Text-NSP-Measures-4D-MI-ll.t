# Before `make install' is performed this script should be runnable with
# `make test'.

##################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..18\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::NSP::Measures::4D::MI::ll;
$loaded = 1;
print "ok 1\n";
print "ok 2\n";

######################### End of black magic.


############ Computing TMI value for some count values.

$ll_value = calculateStatistic( 
                                  n1111=>8,
                                  n1ppp=>306,
                                  np1pp=>83,
                                  npp1p=>83,
                                  nppp1=>57,
                                  n11pp=>8,
                                  n1p1p=>8,
                                  n1pp1=>8,
                                  np11p=>83,
                                  np1p1=>56,
                                  npp11=>56,
                                  n111p=>8,
                                  n11p1=>8,
                                  n1p11=>8,
                                  np111=>56,
                                  npppp=>15180);

if($ll_value >= 2221.772069 && $ll_value <=  2221.773000)
{
    print "ok 3\n";
}
else
{
    print "not ok 3\n";
}

############Error Code check for missing values

%count_values = (n1ppp=>306,
                 np1pp=>83,
                 npp1p=>83,
                 nppp1=>57,
                 n11pp=>8,
                 n1p1p=>8,
                 n1pp1=>8,
                 np11p=>83,
                 np1p1=>56,
                 npp11=>56,
                 n111p=>8,
                 n11p1=>8,
                 n1p11=>8,
                 np111=>56,
                 npppp=>15180);
                 
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

%count_values = (n1111=>8,
                 np1pp=>83,
                 npp1p=>83,
                 nppp1=>57,
                 n11pp=>8,
                 n1p1p=>8,
                 n1pp1=>8,
                 np11p=>83,
                 np1p1=>56,
                 npp11=>56,
                 n111p=>8,
                 n11p1=>8,
                 n1p11=>8,
                 np111=>56,
                 npppp=>15180);

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

%count_values = (n1111=>8,
	         n1ppp=>306,
                 npp1p=>83,
                 nppp1=>57,
                 n11pp=>8,
                 n1p1p=>8,
                 n1pp1=>8,
                 np11p=>83,
                 np1p1=>56,
                 npp11=>56,
                 n111p=>8,
                 n11p1=>8,
                 n1p11=>8,
                 np111=>56,
                 npppp=>15180);

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

%count_values = (n1111=>8,
	         n1ppp=>306,
                 np1pp=>83,
                 npp1p=>83,
                 n11pp=>8,
                 n1p1p=>8,
                 n1pp1=>8,
                 np11p=>83,
                 np1p1=>56,
                 npp11=>56,
                 n111p=>8,
                 n11p1=>8,
                 n1p11=>8,
                 np111=>56,
                 npppp=>15180);

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
%count_values = (n1111=>8,
	         n1ppp=>306,
                 np1pp=>83,
                 npp1p=>83,
                 nppp1=>57,
                 n11pp=>8,
                 n1p1p=>8,
                 n1pp1=>8,
                 np11p=>83,
                 np1p1=>56,
                 n111p=>8,
                 n11p1=>8,
                 n1p11=>8,
                 np111=>56,
                 npppp=>15180);

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
%count_values = (n1111=>8,
	         n1ppp=>306,
                 np1pp=>83,
                 npp1p=>83,
                 nppp1=>57,
                 n11pp=>8,
                 n1p1p=>8,
                 n1pp1=>8,
                 np11p=>83,
                 np1p1=>56,
                 npp11=>56,
                 n111p=>8,
                 n1p11=>8,
                 np111=>56,
                 npppp=>15180);

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
%count_values = (n1111=>8,
	         n1ppp=>306,
                 np1pp=>83,
                 npp1p=>83,
                 nppp1=>57,
                 n11pp=>8,
                 n1p1p=>8,
                 n1pp1=>8,
                 np11p=>83,
                 np1p1=>56,
                 npp11=>56,
                 n111p=>8,
                 n11p1=>8,
                 n1p11=>8,
                 npppp=>15180);

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
%count_values = (n1111=>8,
	         n1ppp=>306,
                 np1pp=>83,
                 npp1p=>83,
                 nppp1=>57,
                 n11pp=>8,
                 n1p1p=>8,
                 n1pp1=>8,
                 np11p=>83,
                 np1p1=>56,
                 npp11=>56,
                 n111p=>8,
                 n11p1=>8,
                 n1p11=>8,
                 np111=>56);

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
%count_values = (n1111=>-8,
	         n1ppp=>306,
                 np1pp=>83,
                 npp1p=>83,
                 nppp1=>57,
                 n11pp=>8,
                 n1p1p=>8,
                 n1pp1=>8,
                 np11p=>83,
                 np1p1=>56,
                 npp11=>56,
                 n111p=>8,
                 n11p1=>8,
                 n1p11=>8,
                 np111=>56,
                 npppp=>15180);

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
%count_values = (n1111=>8,
	         n1ppp=>-306,
                 np1pp=>83,
                 npp1p=>83,
                 nppp1=>57,
                 n11pp=>8,
                 n1p1p=>8,
                 n1pp1=>8,
                 np11p=>83,
                 np1p1=>56,
                 npp11=>56,
                 n111p=>8,
                 n11p1=>8,
                 n1p11=>8,
                 np111=>56,
                 npppp=>15180);

$value = calculateStatistic(%count_values);
$err = getErrorCode();
if($err == 202)
{
  print "ok 13\n";
}
else
{
  print"not ok 13\n";
}


############Error Code check for -ve values
%count_values = (n1111=>8,
	         n1ppp=>306,
                 np1pp=>83,
                 npp1p=>83,
                 nppp1=>57,
                 n11pp=>8,
                 n1p1p=>8,
                 n1pp1=>8,
                 np11p=>83,
                 np1p1=>56,
                 npp11=>56,
                 n111p=>8,
                 n11p1=>8,
                 n1p11=>8,
                 np111=>56,
                 npppp=>-15180);

$value = calculateStatistic(%count_values);
$err = getErrorCode(); 
if($err == 201)
{
  print "ok 14\n";
}
else
{
  print"not ok 14\n";
}


############Error Code check invalid values
%count_values = (n1111=>80,
	         n1ppp=>306,
                 np1pp=>83,
                 npp1p=>83,
                 nppp1=>57,
                 n11pp=>8,
                 n1p1p=>8,
                 n1pp1=>8,
                 np11p=>83,
                 np1p1=>56,
                 npp11=>56,
                 n111p=>8,
                 n11p1=>8,
                 n1p11=>8,
                 np111=>56,
                 npppp=>15180);

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
%count_values = (n1111=>8,
	         n1ppp=>30,
                 np1pp=>830,
                 npp1p=>83,
                 nppp1=>57,
                 n11pp=>8,
                 n1p1p=>8,
                 n1pp1=>8,
                 np11p=>83,
                 np1p1=>56,
                 npp11=>56,
                 n111p=>8,
                 n11p1=>8,
                 n1p11=>8,
                 np111=>560,
                 npppp=>15180);

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
%count_values = (n1111=>8,
	         n1ppp=>306,
                 np1pp=>83,
                 npp1p=>83,
                 nppp1=>57000,
                 n11pp=>8,
                 n1p1p=>8,
                 n1pp1=>8,
                 np11p=>83,
                 np1p1=>56,
                 npp11=>56,
                 n111p=>8,
                 n11p1=>8,
                 n1p11=>8,
                 np111=>56,
                 npppp=>15180);

$value = calculateStatistic(%count_values);

$err = getErrorCode();
if($err == 201)
{
  print "ok 17\n";
}
else
{
  print"not ok 17\n";
}


############## Checking Error code for -ve observed frequency
%count_values = (n1111=>8,
	         n1ppp=>306,
                 np1pp=>83,
                 npp1p=>83,
                 nppp1=>57,
                 n11pp=>8,
                 n1p1p=>8,
                 n1pp1=>8,
                 np11p=>83,
                 np1p1=>56,
                 npp11=>56,
                 n111p=>8,
                 n11p1=>8,
                 n1p11=>8,
                 np111=>5600,
                 npppp=>15180);
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
