#!/usr/bin/perl

use POSIX 'SEEK_SET';
my $file = "tf$$.txt";
$/ = "blah";

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
check_contents("rec0blah");
$a[1] = "rec1blah";
check_contents("rec0blahrec1blah");
$a[2] = "rec2blahblah";             # should we detect this?
                                    # YES! FixedRecLen will strip additional
                                    # recseps on the end
check_contents("rec0blahrec1blahrec2blah");

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
          (split /blah/,$x,-1);
    pop @x if $x[-1] eq ('.' x 10);
    
    $x = (join 'blah',@x) .'blah';
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

