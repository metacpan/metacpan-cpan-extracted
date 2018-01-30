# Run some basic tests to check the randomness.
# These tests need Math-GMPz-0.39 or later.

use strict;
use warnings;
use Win32::GenRandom qw(:all);

eval {require Math::GMPz;};

if($@) {
  print "1..1\n";
  warn "\nSkip all - Math::GMPz could not be loaded (0.39 or later needed)\n";
  print "ok 1\n";

}
else {

  if($Math::GMPz::VERSION < '0.39') {
    print "1..1\n";
    warn "\nSkip all - we have Math-GMPz-$Math::GMPz::VERSION, but we need 0.39 or later\n";
    print "ok 1\n";
    exit 0;
  }

  print "1..2\n";
  my $count = 210;

  my $z = Math::GMPz->new('1' x 20000, 2);

  my ($major, $minor) = (Win32::GetOSVersion())[1, 2];

  my @cgr;
  my @rgr;

  push @cgr, cgr(1, 2500) for 1 .. $count;
  push @rgr, rgr(1, 2500) for 1 .. $count;

  die "Wrong number of random strings in \@cgr" unless @cgr == $count;
  die "Wrong number of random strings in \@rgr" unless @rgr == $count;

  my $ok = 'abcd';

  for(@cgr) {
    Math::GMPz::Rmpz_set_str($z, unpack("b*", $_), 2);
    unless(Math::GMPz::Rmonobit($z)) {
      $ok =~ s/a//;
      warn Math::GMPz::Rmpz_get_str($z, 62), "\n";
    }
    unless(Math::GMPz::Rlong_run($z)) {
      $ok =~ s/b//;
      warn Math::GMPz::Rmpz_get_str($z, 62), "\n";
    }
    unless(Math::GMPz::Rruns($z)) {
      $ok =~ s/c//;
      warn Math::GMPz::Rmpz_get_str($z, 62), "\n";
    }
    unless(Math::GMPz::Rpoker($z)) {
      $ok =~ s/d//;
      warn Math::GMPz::Rmpz_get_str($z, 62), "\n";
    }
  }

  if($ok eq 'abcd') {print "ok 1\n"}
  else {
    warn "\$ok: $ok\n";
    print "not ok 1\n";
  }

  if($major == 5 && $minor == 0) {
    print "\nSkipping test 2 - RtlGenRandom() not available on this system\n";
    print "ok 2\n";
  }
  else {
    $ok = 'abcd';

    for(@rgr) {
      Math::GMPz::Rmpz_set_str($z, unpack("b*", $_), 2);
      unless(Math::GMPz::Rmonobit($z)) {
        $ok =~ s/a//;
        warn Math::GMPz::Rmpz_get_str($z, 62), "\n";
      }
      unless(Math::GMPz::Rlong_run($z)) {
        $ok =~ s/b//;
        warn Math::GMPz::Rmpz_get_str($z, 62), "\n";
      }
      unless(Math::GMPz::Rruns($z)) {
        $ok =~ s/c//;
        warn Math::GMPz::Rmpz_get_str($z, 62), "\n";
      }
      unless(Math::GMPz::Rpoker($z)) {
        $ok =~ s/d//;
        warn Math::GMPz::Rmpz_get_str($z, 62), "\n";
      }
    }

    if($ok eq 'abcd') {print "ok 2\n"}
    else {
      warn "\$ok: $ok\n";
      print "not ok 2\n";
    }
  }
}

__END__

I had a test 1 failure because the (base 62) string:

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

which was generated by Win32::GenRandom failed the Rruns test (test 1c).

g[0] is 2737 which exceeds the max allowed (2733).
