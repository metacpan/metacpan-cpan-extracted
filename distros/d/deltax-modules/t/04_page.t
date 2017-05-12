#!/usr/bin/perl

my $num = 1;

sub ok {
  my $ok = shift;
  if ($ok) { print "ok $num\n"; }
  else { print "not ok $num\n"; }
  $num++;
}

print "1..5\n";

use DeltaX::Page;

ok(1);

sub test1 {
	return shift;
}
sub test2 {
	return "test2:".shift;
}

my $page = new DeltaX::Page('t/04_page1.pg',
	test1=>\&test1, test2=>\&test2,
	_defs=>['def1','def2']);
ok(defined $page);
ok($page->isa('DeltaX::Page'));
ok($page->compile());

# read expected output
my $out = '';
if (open INF, "t/04_page1.out") {
	while (<INF>) { $out .= $_; }
	close INF;
}
print $page->{translated};
ok($page->{translated} eq $out);

