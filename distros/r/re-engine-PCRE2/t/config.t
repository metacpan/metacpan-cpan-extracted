use strict;
use Test::More;
use Config;
use re::engine::PCRE2;

my $qr = qr/(a(b?))/;
if ($] < 5.013 && $qr->_alloptions() == 4294967295) {
  plan skip_all => "methods return -1";
} else {
  plan tests => 39;
}
my %m =
  (
   _alloptions => 64,
   _argoptions => 64,
   backrefmax => 0,
   bsr => 1,
   capturecount => 2,
   firstcodetype => 1,
   firstcodeunit => 97,
   #framesize => undef,
   #size => 155,
   #hasbackslashc => 0,
   hascrorlf => 0,
   #heaplimit => undef,
   jchanged => 0,
   #jitsize => 155,
   lastcodetype => 0,
   lastcodeunit => 0,
   matchempty => 0,
   matchlimit => undef,
   maxlookbehind => 0,
   minlength => 1,
   namecount => 0,
   nameentrysize => 0,
   newline => 2,
  );
# default build-time configs
my %o =
  (
   BSR => 1,
   NEWLINE => 2,
   UNICODE => 1,
   PARENSLIMIT => 250,
   RECURSIONLIMIT => 10000000,
   MATCHLIMIT => 10000000,
   #DEPTHLIMIT => 10000000 or undef,
   #STACKRECURSE => 1 or 0 in newer libs, obsolete
   #HEAPLIMIT => 20000000 or undef,
  );

for (sort keys %m) {
  is($qr->$_, $m{$_}, "$_ $m{$_}");
}
my $s = $qr->size;
ok($s > 100, "size $s"); # 131 with 32bit, 155 with 64bit
$s = $qr->framesize;
ok($s < 1000 || !defined($s), "framesize $s");
$s = $qr->hasbackslashc;
ok($s == 0 || !defined($s), "hasbackslashc $s");
$s = $qr->heaplimit;
ok($s == 4294967295 || !defined($s), "heaplimit $s");

if (re::engine::PCRE2::JIT) {
  $s = $qr->jitsize;
  ok($s > 50, "jitsize $s");
  is(re::engine::PCRE2::config('JIT'), 1, "config JIT 1");
  $s = re::engine::PCRE2::config('JITTARGET');
  ok($s, "config JITTARGET \"$s\"");
} else {
  $s = $qr->jitsize;
  is($s, 0, "no jitsize 0");
  is(re::engine::PCRE2::config('JIT'), 0, "config JIT 0");
  $s = re::engine::PCRE2::config('JITTARGET');
  is($s, undef, "no config JITTARGET");
}

eval { $s = re::engine::PCRE2::config('invalid'); };
# note: $s stays at JITTARGET. XS returns empty
like($@, qr/^Invalid config argument invalid/, "config invalid");
for (sort keys %o) {
  is(re::engine::PCRE2::config($_), $o{$_}, "config $_ $o{$_}");
}
$s = re::engine::PCRE2::config("DEPTHLIMIT");
ok(!defined $s || $s == 10000000, "config DEPTHLIMIT $s");
$s = re::engine::PCRE2::config("HEAPLIMIT");
ok(!defined $s || $s == 20000000, "config HEAPLIMIT $s");
$s = re::engine::PCRE2::config("STACKRECURSE");
ok($s == 0 || $s == 1, "config STACKRECURSE $s");
$s = re::engine::PCRE2::config("UNICODE_VERSION");
like($s, qr/^\d/, "config UNICODE_VERSION \"$s\"");
$s = re::engine::PCRE2::config("VERSION");
like($s, qr/^10\.*/, "config VERSION \"$s\"");

{ use bytes;
  my $q = qr/[a-z]/;
  my $tbl = $q->firstbitmap;
  is(length $tbl, 32, 'firstbitmap table');
  is(join(" ",unpack("C*", $tbl)), '0 0 0 0 0 0 0 0 0 0 0 0 254 255 255 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0');
}
