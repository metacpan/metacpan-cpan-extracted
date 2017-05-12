#!/usr/bin/perl

use POSIX 'SEEK_SET';
my $file = "tf$$.txt";
$: = Tie::File::_default_recsep();

print "1..5\n";

my $N = 1;
BEGIN {
    eval {require Tie::File::FixedRecLen};

    if ($@) {
      print "1..0 # skipped... cannot use Tie::File::FixedRecLen with your version of Tie::File
";
      exit;
    }
}

print "ok $N\n"; $N++;

my $o = tie @a, 'Tie::File::FixedRecLen', $file, record_length => 10, pad_char => '.', autodefer => 0;
print $o ? "ok $N\n" : "not ok $N\n";
$N++;

$a[0] = 'rec0';
check_contents("rec0${:}");
$a[1] = "rec1${:}";
check_contents("rec0${:}rec1${:}");
$a[2] = "rec2${:}${:}";             # should we detect this?
                                    # YES! with FixedRecLen it is lopped off
                                    # like a septic limb.
check_contents("rec0${:}rec1${:}rec2${:}");

sub check_contents {
  my $x = shift;
  local *FH = $o->{fh};
  seek FH, 0, SEEK_SET;
  my $a;
  { local $/; $a = <FH> }
  $a = "" unless defined $a;

  # munge $x
  if ($x ne '') {
    my @x = 
      map {('.' x (10 - length($_))) . $_}
          (split /${:}/,$x,-1);
    pop @x if $x[-1] eq ('.' x 10);
    
    $x = (join ${:},@x) .${:};
  }

  if ($a eq $x) {
    print "ok $N\n";
  } else {
    my $msg = "not ok $N # expected <$x>, got <$a>";
    ctrlfix($msg);
    print "$msg\n";
  }
  $N++;
}

sub ctrlfix {
  for (@_) {
    s/\n/\\n/g;
    s/\r/\\r/g;
  }
}

END {
  undef $o;
  untie @a;
  1 while unlink $file;
}

