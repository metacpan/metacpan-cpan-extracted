use Test;
use strict;
BEGIN { plan tests => 1 };

use Win32::ToolHelp;
ok(1);

my @ps = Win32::ToolHelp::GetProcesses;
#print 'ref(\@ps)=', ref(\@ps), "\n";
ok(ref(\@ps) eq "ARRAY");
#print 'scalar(@ps)=', scalar(@ps), "\n";
ok(scalar(@ps) > 0);

foreach my $p (@ps)
{
	#print 'ref($p)=', ref($p), "\n";
	ok(ref($p) eq "ARRAY");
	#print 'scalar(@$p)=', scalar(@$p), "\n";
	ok(scalar(@$p) == 9);
	#print $$p[0], " ", $$p[1], " ", $$p[2], " ", $$p[3], " ", $$p[4], " ", $$p[4], " ", $$p[6], " ", $$p[7], " ", $$p[8], "\n";
	for my $i (0 .. 8)
	{
		#print 'ref(\$$p[0])=', ref(\$$p[0]), "\n";
		ok(ref(\$$p[$i]) eq "SCALAR");
	}

	my @ms = Win32::ToolHelp::GetProcessModules($$p[1]);
	#print 'ref(\@ms)=', ref(\@ms), "\n";
	ok(ref(\@ms) eq "ARRAY");
	#print 'scalar(@ms)=', scalar(@ms), "\n";
	ok(scalar(@ms) >= 0);

	foreach my $m (@ms)
	{
		#print 'ref($m)=', ref($m), "\n";
		ok(ref($m) eq "ARRAY");
		#print 'scalar(@$m)=', scalar(@$m), "\n";
		ok(scalar(@$m) == 9);
		#print $$m[0], " ", $$m[1], " ", $$m[2], " ", $$m[3], " ", $$m[4], " ", $$m[4], " ", $$m[6], " ", $$m[7], " ", $$m[8], "\n";
		for my $i (0 .. 8)
		{
			#print 'ref(\$$m[0])=', ref(\$$m[0]), "\n";
			ok(ref(\$$m[$i]) eq "SCALAR");
		}
	}
}

my @p = Win32::ToolHelp::GetProcess($$);
#print 'ref(\@p)=', ref(\@p), "\n";
ok(ref(\@p) eq "ARRAY");
#print 'scalar(@p)=', scalar(@p), "\n";
ok(scalar(@p) == 9);
#print $p[0], " ", $p[1], " ", $p[2], " ", $p[3], " ", $p[4], " ", $p[4], " ", $p[6], " ", $p[7], " ", $p[8], "\n";
for my $i (0 .. 8)
{
	#print 'ref(\$p[0])=', ref(\$p[0]), "\n";
	ok(ref(\$p[$i]) eq "SCALAR");
}

my @m = Win32::ToolHelp::GetProcessModule($$, 1);
#print 'ref(\@m)=', ref(\@m), "\n";
ok(ref(\@m) eq "ARRAY");
#print 'scalar(@m)=', scalar(@m), "\n";
ok(scalar(@m) == 9);
#print $m[0], " ", $m[1], " ", $m[2], " ", $m[3], " ", $m[4], " ", $m[4], " ", $m[6], " ", $m[7], " ", $m[8], "\n";
for my $i (0 .. 8)
{
	#print 'ref(\$m[0])=', ref(\$m[0]), "\n";
	ok(ref(\$m[$i]) eq "SCALAR");
}

my @m = Win32::ToolHelp::GetProcessMainModule($$);
#print 'ref(\@m)=', ref(\@m), "\n";
ok(ref(\@m) eq "ARRAY");
#print 'scalar(@m)=', scalar(@m), "\n";
ok(scalar(@m) == 9);
#print $m[0], " ", $m[1], " ", $m[2], " ", $m[3], " ", $m[4], " ", $m[4], " ", $m[6], " ", $m[7], " ", $m[8], "\n";
for my $i (0 .. 8)
{
	#print 'ref(\$m[0])=', ref(\$m[0]), "\n";
	ok(ref(\$m[$i]) eq "SCALAR");
}

my @p = Win32::ToolHelp::SearchProcess("perl.exe");
#print 'ref(\@p)=', ref(\@p), "\n";
ok(ref(\@p) eq "ARRAY");
#print 'scalar(@p)=', scalar(@p), "\n";
ok(scalar(@p) == 9);
#print $p[0], " ", $p[1], " ", $p[2], " ", $p[3], " ", $p[4], " ", $p[4], " ", $p[6], " ", $p[7], " ", $p[8], "\n";
for my $i (0 .. 8)
{
	#print 'ref(\$p[0])=', ref(\$p[0]), "\n";
	ok(ref(\$p[$i]) eq "SCALAR");
}

my @m = Win32::ToolHelp::SearchProcessModule($$, "perl.exe");
#print 'ref(\@m)=', ref(\@m), "\n";
ok(ref(\@m) eq "ARRAY");
#print 'scalar(@m)=', scalar(@m), "\n";
ok(scalar(@m) == 9);
#print $m[0], " ", $m[1], " ", $m[2], " ", $m[3], " ", $m[4], " ", $m[4], " ", $m[6], " ", $m[7], " ", $m[8], "\n";
for my $i (0 .. 8)
{
	#print 'ref(\$m[0])=', ref(\$m[0]), "\n";
	ok(ref(\$m[$i]) eq "SCALAR");
}

my @m = Win32::ToolHelp::SearchProcessMainModule("perl.exe");
#print 'ref(\@m)=', ref(\@m), "\n";
ok(ref(\@m) eq "ARRAY");
#print 'scalar(@m)=', scalar(@m), "\n";
ok(scalar(@m) == 9);
#print $m[0], " ", $m[1], " ", $m[2], " ", $m[3], " ", $m[4], " ", $m[4], " ", $m[6], " ", $m[7], " ", $m[8], "\n";
for my $i (0 .. 8)
{
	#print 'ref(\$m[0])=', ref(\$m[0]), "\n";
	ok(ref(\$m[$i]) eq "SCALAR");
}
