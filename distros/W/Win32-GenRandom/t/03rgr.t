use strict;
use warnings;
use Win32;
use Win32::GenRandom qw(:all);
use Config;

my $max_uv_digits = ($Config::Config{ivsize} * 10) / 4;

if(!$Win32::GenRandom::rtl_avail) {
  print "1..1\n";

  eval{rgr(1, 100)};

  if($@ =~ /RtlGenRandom not available on Windows 2000/) {print "ok 1\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok 1\n";
  }
}
else {
  print "1..11\n";

  my $s1 = rgr(1, 100);
  my $s2 = rgr(1, 100);

  if(length $s1 == 100) {print "ok 1\n"}
  else {
    warn "length \$s1: ", length $s1, "\n";
    print "not ok 1\n";
  }

  if(length $s2 == 100) {print "ok 2\n"}
  else {
    warn "length \$s2: ", length $s2, "\n";
    print "not ok 1\n";
  }

  if($s1 eq $s2) {
    print "not ok 3\n";
  }
  else {print "ok 3\n"}

  my $ok = 'ab';
  my $how_many = 115;
  my $len = 659;
  my @s = rgr($how_many, $len);

  for(my $i = 1; $i < @s; $i++) {
    if(length($s[$i]) != $len) {
      $ok =~ s/a//;
      warn "\nlength(\$s[$i]) is ", length($s[$i]), "\n";
    }
  }

  for(my $i = 1; $i < @s; $i++) {
    for(my $j = 0; $j < $i; $j++) {
      if($s[$j] eq $s[$i]) {
        $ok =~ s/b//;
        warn "\n\$s[$j] and \$s[$i] are the same\n";
      }
    }
  }

  if($ok eq 'ab') {print "ok 4\n"}
  else {
    warn "\$ok = $ok\n";
    print "not ok 4\n";
  }

  if(@s == $how_many) {print "ok 5\n"}
  else {
    warn "\n\@s: ", scalar(@s), "\n";
    print "not ok 5\n";
  }

  @s = rgr_uv($how_many);

  if(@s == $how_many) {print "ok 6\n"}
  else {
    warn "\n\@s: ", scalar(@s), "\n";
    print "not ok 6\n";
  }

  $ok = 1;

  for(my $i = 1; $i < @s; $i++) {
    for(my $j = 0; $j < $i; $j++) {
      if($s[$j] == $s[$i]) {
        $ok = 0;
        warn "\n\$s[$j] and \$s[$i] are the same value\n";
      }
    }
  }

  if($ok) {print "ok 7\n"}
  else {print "not ok 7\n"}

  $ok = 1;

  for(@s) {
    unless($_ =~ /[1-9]/ && $_ !~ /\D/ && length($_) <= $max_uv_digits) {
      $ok = 0;
      warn "\nrgr_uv() function returned an unacceptable value ($_)\n";
    }
  }

  if($ok) {print "ok 8\n"}
  else {print "not ok 8\n"}

  @s = rgr_32($how_many);

  if(@s == $how_many) {print "ok 9\n"}
  else {
    warn "\n\@s: ", scalar(@s), "\n";
    print "not ok 9\n";
  }

  $ok = 1;

  for(my $i = 1; $i < @s; $i++) {
    for(my $j = 0; $j < $i; $j++) {
      if($s[$j] == $s[$i]) {
        $ok = 0;
        warn "\n\$s[$j] and \$s[$i] are the same value\n";
      }
    }
  }

  if($ok) {print "ok 10\n"}
  else {print "not ok 10\n"}

  $ok = 1;

  for(@s) {
    unless($_ =~ /[1-9]/ && $_ !~ /\D/ && length($_) <= 10) {
      $ok = 0;
      warn "\nrgr_32() function returned an unacceptable value ($_)\n";
    }
  }

  if($ok) {print "ok 11\n"}
  else {print "not ok 11\n"}

} #else
