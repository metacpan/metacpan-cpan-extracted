use strict;
use warnings;
use Win32::GenRandom qw(:all);
use Config;

my $count = 16;

my $c = $Win32::GenRandom::rtl_avail ? $count * 2 : $count + 2;
my $init = $Win32::GenRandom::rtl_avail ? 'RtlGenRandom' : 'CryptGenRandom';

print "1..$c\n";

my $max_uv_digits = ($Config::Config{ivsize} * 10) / 4;

my $s1 = gr(1, 100);
my $s2 = gr(1, 100);
my $s3 = gr(100);
my @s =  gr(100);

if(length $s1 == 100 && @s == 1) {print "ok 1\n"}
else {
  warn "length \$s1: ", length $s1, "\n", "\@s: ", scalar @s, "\n";
  print "not ok 1\n";
}

if(length $s2 == 100 && length $s3 == 100 && length $s[0] == 100) {print "ok 2\n"}
else {
  warn "length \$s2: ", length $s2, "\nlength \$s3: ", length $s3, "\nlength \$s[0]: ",
        length $s[0], "\n";
  print "not ok 2\n";
}

if($s1 eq $s2 || $s1 eq $s3 || $s2 eq $s3 || $s1 eq $s[0] || $s2 eq $s[0] || $s3 eq $s[0]) {
  print "not ok 3\n";
}
else {print "ok 3\n"}

my $ok = 'ab';
my $how_many = 115;
my $len = 659;
@s = gr($how_many, $len);

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

@s = gr_uv($how_many);

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
    warn "\ngr_uv() function returned an unacceptable value ($_)\n";
  }
}

if($ok) {print "ok 8\n"}
else {print "not ok 8\n"}

########################
########################

@s = gr_32($how_many);

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
    warn "\ngr_32() function returned an unacceptable value ($_)\n";
  }
}

if($ok) {print "ok 11\n"}
else {print "not ok 11\n"}

if(which_crypto() eq $init) { print "ok 12\n"}
else {
  warn "\nExpected $init; got ", which_crypto(), "\n";
  print "not ok 12\n";
}

$ok = 1;

$s1 = gr_uv();

unless($s1 =~ /[1-9]/ && $s1 !~ /\D/ && length($s1) <= $max_uv_digits) {
  $ok = 0;
  warn "\ngr_uv() function returned an unacceptable value ($s1)\n";
}

if($ok) {print "ok 13\n"}
else {print "not ok 13\n"}

$ok = 1;

$s1 = gr_32();

unless($s1 =~ /[1-9]/ && $s1 !~ /\D/ && length($s1) <= 10) {
  $ok = 0;
  warn "\ngr_32() function returned an unacceptable value ($s1)\n";
}

if($ok) {print "ok 14\n"}
else {print "not ok 14\n"}

$ok = 1;

@s = gr_uv();

unless($s[0] =~ /[1-9]/ && $s[0] !~ /\D/ && length($s[0]) <= $max_uv_digits && @s == 1) {
  $ok = 0;
  warn "\ngr_uv() function returned an unacceptable value ($s[0])\n";
}

if($ok) {print "ok 15\n"}
else {print "not ok 15\n"}

$ok = 1;

@s = gr_32();

unless($s[0] =~ /[1-9]/ && $s[0] !~ /\D/ && length($s[0]) <= 10 && @s == 1) {
  $ok = 0;
  warn "\ngr_32() function returned an unacceptable value ($s[0])\n";
}

if($ok) {print "ok 16\n"}
else {print "not ok 16\n"}

# Toggle the value of $Win32::GenRandom::rtl_avail.
$Win32::GenRandom::rtl_avail = $Win32::GenRandom::rtl_avail ? 0 : 1;

if($Win32::GenRandom::rtl_avail) {

  eval{gr(1, 100)};

  if($@ =~ /RtlGenRandom not available on Windows 2000/) {print "ok ", $count + 1, "\n"}
  else {
    warn "\$\@: $@\n";
    print "not ok ", $count + 1, "\n";
  }

  if(which_crypto() eq 'RtlGenRandom') { print "ok ", $count + 2, "\n"}
  else {
    warn "\nExpected 'RtlGenRandom'; got ", which_crypto(), "\n";
    print "not ok ", $count + 2, "\n";
  }

}
else {
  my $s1 = gr(1, 100);
  my $s2 = gr(1, 100);
  my $s3 = gr(100);
  my @s =  gr(100);

  if(length $s1 == 100 && @s == 1) {print "ok ", $count + 1, "\n"}
  else {
    warn "length \$s1: ", length $s1, "\n", "\@s: ", scalar @s, "\n";
    print "not ok ", $count + 1,  "\n";
  }

  if(length $s2 == 100 && length $s3 == 100 && length $s[0] == 100) {print "ok ", $count + 2, "\n"}
  else {
    warn "length \$s2: ", length $s2, "\nlength \$s3: ", length $s3, "\nlength \$s[0]: ",
         length $s[0], "\n";
    print "not ok ", $count + 2, "\n";
  }

  if($s1 eq $s2 || $s1 eq $s3 || $s2 eq $s3 || $s1 eq $s[0] || $s2 eq $s[0] || $s3 eq $s[0]) {
    print "not ok", $count + 3, "\n";
  }
  else {print "ok ", $count + 3, "\n"}

  my $ok = 'ab';
  my $how_many = 115;
  my $len = 659;
  @s = gr($how_many, $len);

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

  if($ok eq 'ab') {print "ok ", $count + 4, "\n"}
  else {
    warn "\$ok = $ok\n";
    print "not ok ", $count + 4, "\n";
  }

  if(@s == $how_many) {print "ok ", $count + 5, "\n"}
  else {
    warn "\n\@s: ", scalar(@s), "\n";
    print "not ok ", $count + 5, "\n";
  }

  @s = gr_uv($how_many);

  if(@s == $how_many) {print "ok ", $count + 6, "\n"}
  else {
    warn "\n\@s: ", scalar(@s), "\n";
    print "not ok ", $count + 6, "\n";
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

  if($ok) {print "ok ", $count + 7, "\n"}
  else {print "not ok ", $count + 7, "\n"}

  $ok = 1;

  for(@s) {
    unless($_ =~ /[1-9]/ && $_ !~ /\D/ && length($_) <= $max_uv_digits) {
      $ok = 0;
      warn "\ngr_uv() function returned an unacceptable value ($_)\n";
    }
  }

  if($ok) {print "ok ", $count + 8, "\n"}
  else {print "not ok ", $count + 8, "\n"}

  ########################
  ########################

  @s = gr_32($how_many);

  if(@s == $how_many) {print "ok ", $count + 9, "\n"}
  else {
    warn "\n\@s: ", scalar(@s), "\n";
    print "not ok ", $count + 9, "\n";
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

  if($ok) {print "ok ", $count + 10, "\n"}
  else {print "not ok ", $count + 10, "\n"}

  $ok = 1;

  for(@s) {
    unless($_ =~ /[1-9]/ && $_ !~ /\D/ && length($_) <= 10) {
      $ok = 0;
      warn "\ngr_32() function returned an unacceptable value ($_)\n";
    }
  }

  if($ok) {print "ok ", $count + 11, "\n"}
  else {print "not ok ", $count + 11, "\n"}

  if(which_crypto() eq 'CryptGenRandom') { print "ok ", $count + 12, "\n"}
  else {
    warn "\nExpected 'CryptGenRandom'; got ", which_crypto(), "\n";
    print "not ok ", $count + 12, "\n";
  }

  $ok = 1;

  $s1 = gr_uv();

  unless($s1 =~ /[1-9]/ && $s1 !~ /\D/ && length($s1) <= $max_uv_digits) {
    $ok = 0;
    warn "\ngr_uv() function returned an unacceptable value ($s1)\n";
  }

  if($ok) {print "ok ", $count + 13, "\n"}
  else {print "not ok ", $count + 13, "\n"}

  $ok = 1;

  $s1 = gr_32();

  unless($s1 =~ /[1-9]/ && $s1 !~ /\D/ && length($s1) <= 10) {
    $ok = 0;
    warn "\ngr_32() function returned an unacceptable value ($s1)\n";
  }

  if($ok) {print "ok ", $count + 14, "\n"}
  else {print "not ok ", $count + 14, "\n"}

  $ok = 1;

  @s = gr_uv();

  unless($s[0] =~ /[1-9]/ && $s[0] !~ /\D/ && length($s[0]) <= $max_uv_digits && @s == 1) {
    $ok = 0;
    warn "\ngr_uv() function returned an unacceptable value ($s[0])\n";
  }

  if($ok) {print "ok ", $count + 15, "\n"}
  else {print "not ok ", $count + 15, "\n"}

  $ok = 1;

  @s = gr_32();

  unless($s[0] =~ /[1-9]/ && $s[0] !~ /\D/ && length($s[0]) <= 10 && @s == 1) {
    $ok = 0;
    warn "\ngr_32() function returned an unacceptable value ($s[0])\n";
  }

  if($ok) {print "ok ", $count + 16, "\n"}
  else {print "not ok ", $count + 16, "\n"}
}

