
##################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::NSP::Measures::2D;
$loaded = 1;
print "ok 1\n";


############ Call Text::NSP::Measures::2D::computeObserved Values method for error testing

my %count_values = (n11 => 10,
                    n1p => 20,
                    np1 => 20,
                    npp => 60);

Text::NSP::Measures::2D::computeMarginalTotals(\%count_values);
$err = getErrorCode();
if(defined $err)
{
  print "not ok 2\n";
}
if( !(Text::NSP::Measures::2D::computeObservedValues(\%count_values)) )
{
  print "not ok 2\n";
}
else
{
  if($n11 == 10 and $n12 == 10 and $n21 == 10 and $n22 == 30)
  {
    print "ok 2\n";
  }
  else
  {
    print "not ok 2\n";
  }
}

############Error Code check for missing values

%count_values = (n1p => 20,
                 np1 => 20,
                 npp => 60);

Text::NSP::Measures::2D::computeMarginalTotals(\%count_values);
$err = getErrorCode();
if(defined $err)
{
  print "not ok 2\n";
}
if( !(Text::NSP::Measures::2D::computeObservedValues(\%count_values)) )
{
  $err = getErrorCode();
  if($err == 200)
  {
    print "ok 3\n";
  }
  else
  {
    print"not ok 3\n";
  }
}
else
{
  print"not ok 3\n";
}

############Error Code check for missing values

%count_values = (n11 =>10,
                 np1 => 20,
                 npp => 60);

if(!(Text::NSP::Measures::2D::computeMarginalTotals(\%count_values)) )
{
  $err = getErrorCode();
  if($err == 200)
  {
    print "ok 4\n";
  }
  else
  {
    print"not ok 4\n";
  }
}
else
{
  print"not ok 4\n";
}

############Error Code check for missing values

%count_values = (n11=>10,
                 n1p => 20,
                 np1 => 20);

if(!(Text::NSP::Measures::2D::computeMarginalTotals(\%count_values)) )
{
  $err = getErrorCode();
  if($err == 200)
  {
    print "ok 5\n";
  }
  else
  {
    print"not ok 5\n";
  }
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

Text::NSP::Measures::2D::computeMarginalTotals(\%count_values);
$err = getErrorCode();
if(defined $err)
{
  print "not ok 2\n";
}
if( !(Text::NSP::Measures::2D::computeObservedValues(\%count_values)) )
{
  $err = getErrorCode();
  if($err == 201)
  {
    print "ok 6\n";
  }
  else
  {
    print"not ok 6\n";
  }
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

if(!(Text::NSP::Measures::2D::computeMarginalTotals(\%count_values)) )
{
  $err = getErrorCode();
  if($err == 204)
  {
    print "ok 7\n";
  }
  else
  {
    print"not ok 7\n";
  }
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

if(!(Text::NSP::Measures::2D::computeMarginalTotals(\%count_values)) )
{
  $err = getErrorCode();
  if($err == 204)
  {
    print "ok 8\n";
  }
  else
  {
    print"not ok 8\n";
  }
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

Text::NSP::Measures::2D::computeMarginalTotals(\%count_values);
$err = getErrorCode();
if(defined $err)
{
  print "not ok 2\n";
}
if( !(Text::NSP::Measures::2D::computeObservedValues(\%count_values)) )
{
  $err = getErrorCode();
  if($err == 202)
  {
    print "ok 9\n";
  }
  else
  {
    print"not ok 9\n";
  }
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

Text::NSP::Measures::2D::computeMarginalTotals(\%count_values);
$err = getErrorCode();
if(defined $err)
{
  print "not ok 2\n";
}
if( !(Text::NSP::Measures::2D::computeObservedValues(\%count_values)) )
{
  $err = getErrorCode();
  if($err == 202)
  {
    print "ok 10\n";
  }
  else
  {
    print"not ok 10\n";
  }
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

if(!(Text::NSP::Measures::2D::computeMarginalTotals(\%count_values)) )
{
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
}
else
{
  print"not ok 11\n";
}

############## Checking Error code for -ve observed frequency
%count_values = (n11 => 10,
                 n1p => 20,
                 np1 => 11,
                 npp => 20);

Text::NSP::Measures::2D::computeMarginalTotals(\%count_values);
$err = getErrorCode();
if(defined $err)
{
  print "not ok 2\n";
}
if( !(Text::NSP::Measures::2D::computeObservedValues(\%count_values)) )
{
  $err = getErrorCode();
  if($err==201)
  {
      print "ok 12\n";
  }
  else
  {
      print "not ok 12\n";
  }
}
else
{
  print"not ok 12\n";
}


############ Check if class is abstract.

calculateStatistic();
$errorCode = getErrorCode();
if($errorCode == 101)
{
    print "ok 13\n";
}
else
{
    print "not ok 13\n";
}
