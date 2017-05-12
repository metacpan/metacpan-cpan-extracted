BEGIN { $| = 1; print "1..26\n"; }
use warnings;
use strict;

# Test that we can load the module
my $loaded;
END {print "not ok 1\n" unless $loaded;}
use Want;
$loaded = 1;
print "ok 1\n";

# Test for Damian's loop bug

sub do_something_anything {}
my $ok = 2;
my @answers = (1,1,0,0,1,1,0,0,1,1,0,0,
               0,0,1,1,0,0,1,1,0,0,1,1);
sub okedoke {
  print((shift == shift @answers? "ok " : "not ok "),
  	$ok++, "\n");
}

my $flipflop = 0;

sub foo {
	okedoke(want 'BOOL');
	return $flipflop=!$flipflop;   # alternate true and false
}

for (1..3) {
	while (foo() ) {
		do_something_anything;
	}
	while (my $answer = foo() ) {
		do_something_anything;
	}
}

sub bar {
	okedoke(want '!BOOL');
	return $flipflop=!$flipflop;   # alternate true and false
}

for (1..3) {
	while (bar() ) {
		do_something_anything;
	}
	my $answer;
	while ($answer = bar() ) {
		do_something_anything;
	}
}

print (@answers == 0 ? "ok 26\n" : "not ok 26\n");