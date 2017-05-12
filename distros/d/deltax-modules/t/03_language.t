#!/usr/bin/perl

my $num = 1;

sub ok {
  my $ok = shift;
  if ($ok) { print "ok $num\n"; }
  else { print "not ok $num\n"; }
  $num++;
}

print "1..11\n";

use DeltaX::Language;

ok(1);

my $lang_file = new DeltaX::Language('t/03_lang1.TST');
ok(defined $lang_file);
ok($lang_file->isa('DeltaX::Language'));

my $txt = $lang_file->read();
ok(defined $txt);
ok($txt->{'t1'} eq 'val1');
ok($txt->{'t2'} eq 'val2');

$lang_file = new DeltaX::Language('t/03_lang2.TST');
ok(defined $lang_file);
ok($lang_file->isa('DeltaX::Language'));

$txt = $lang_file->read();
ok(defined $txt);
ok($txt->{'t1'} eq 'val1');
ok($txt->{'t3'} eq 'val3');
