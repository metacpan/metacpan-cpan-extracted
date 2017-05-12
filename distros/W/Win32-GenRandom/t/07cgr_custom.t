use strict;
use warnings;
use Win32::GenRandom qw(:all);
use Config;

print "1..15\n";

my $max_uv_digits = ($Config::Config{ivsize} * 10) / 4;

my $s1 = cgr_custom(1, 100, '', '', PROV_RSA_FULL, CRYPT_SILENT | CRYPT_VERIFYCONTEXT);
my $s2 = cgr_custom(1, 100, '', '', PROV_RSA_FULL, CRYPT_SILENT | CRYPT_VERIFYCONTEXT);
my $s3 = cgr_custom(100, '', '', PROV_RSA_FULL, CRYPT_SILENT | CRYPT_VERIFYCONTEXT);
my @s  = cgr_custom(100, '', '', PROV_RSA_FULL, CRYPT_SILENT | CRYPT_VERIFYCONTEXT);

if(length $s1 == 100 && @s == 1) {print "ok 1\n"}
else {
  warn "\nlength \$s1: ", length $s1, "\n";
  print "not ok 1\n";
}

if(length $s2 == 100 && length $s3 == 100 && length $s[0] == 100) {print "ok 2\n"}
else {
  warn "\nlength \$s2: ", length $s2, "\n";
  warn "length \$s3: ", length $s3, "\n";
  warn "length \$s[0]: ", length $s[0], "\n";
  print "not ok 2\n";
}

if($s1 eq $s2 || $s1 eq $s3 || $s2 eq $s3 || $s1 eq $s[0] || $s2 eq $s[0] || $s3 eq $s[0]) {
  print "not ok 3\n";
}
else {print "ok 3\n"}

my $ok = 'ab';
my $how_many = 115;
my $len = 659;
@s = cgr_custom($how_many, $len, '', '', PROV_RSA_FULL, CRYPT_SILENT | CRYPT_VERIFYCONTEXT);

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

@s = cgr_custom_uv($how_many, '', '', PROV_RSA_FULL, CRYPT_SILENT | CRYPT_VERIFYCONTEXT);

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
    warn "\ncgr_custom_uv() function returned an unacceptable value ($_)\n";
  }
}

if($ok) {print "ok 8\n"}
else {print "not ok 8\n"}

########################
########################

@s = cgr_custom_32($how_many, '', '', PROV_RSA_FULL, CRYPT_SILENT | CRYPT_VERIFYCONTEXT);

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
    warn "\ncgr_custom_32() function returned an unacceptable value ($_)\n";
  }
}

if($ok) {print "ok 11\n"}
else {print "not ok 11\n"}

$s1 = cgr_custom_32('', '', PROV_RSA_FULL, CRYPT_SILENT | CRYPT_VERIFYCONTEXT);

unless($s1 =~ /[1-9]/ && $s1 !~ /\D/ && length($s1) <= 10) {
  warn "\ncgr_custom_32() function returned an unacceptable value ($s1)\n";
  print "not ok 12\n";
}
else {
  print "ok 12\n";
}

$s1 = cgr_custom_uv('', '', PROV_RSA_FULL, CRYPT_SILENT | CRYPT_VERIFYCONTEXT);

unless($s1 =~ /[1-9]/ && $s1 !~ /\D/ && length($s1) <= $max_uv_digits) {
  warn "\ncgr_custom_uv() function returned an unacceptable value ($s1)\n";
  print "not ok 13\n";
}
else {
  print "ok 13\n";
}

@s = cgr_custom_32('', '', PROV_RSA_FULL, CRYPT_SILENT | CRYPT_VERIFYCONTEXT);

unless($s[0] =~ /[1-9]/ && $s[0] !~ /\D/ && length($s[0]) <= 10 && @s == 1) {
  warn "\ncgr_custom_32() function returned an unacceptable value ($s[0])\n";
  print "not ok 14\n";
}
else {
  print "ok 14\n";
}

@s = cgr_custom_uv('', '', PROV_RSA_FULL, CRYPT_SILENT | CRYPT_VERIFYCONTEXT);

unless($s[0] =~ /[1-9]/ && $s[0] !~ /\D/ && length($s[0]) <= $max_uv_digits && @s == 1) {
  warn "\ncgr_custom_uv() function returned an unacceptable value ($s[0])\n";
  print "not ok 15\n";
}
else {
  print "ok 15\n";
}
