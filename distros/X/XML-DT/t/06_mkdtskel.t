#-*- cperl -*-

use Test::More tests => 2;
use XML::DT;

{
  open TMP, ">_${$}_" or die "Cannot create temporary file\n";
  select TMP;
  mkdtskel("t/05_input.xml");
  close TMP;

  open A, "_${$}_";
  open B, "t/06_output.pl";
  my $ok = 1;
  while(defined($a = <A>) && defined($b = <B>)) {
    $ok = 0 unless $a eq $b;
  }
  close B;
  close A;

  ok($ok);

  unlink "_${$}_";
}

###-----------------
{
  open TMP, ">_${$}_" or die "Cannot create temporary file\n";
  select TMP;
  mkdtskel_fromDTD("t/06_input.dtd");
  close TMP;

  open A, "_${$}_";
  open B, "t/06_dtdout.pl";
  my $ok = 1;
  while(defined($a = <A>) && defined($b = <B>)) {
    $ok = 0 unless $a eq $b;
  }
  close B;
  close A;

  ok($ok);

  unlink "_${$}_";
}
