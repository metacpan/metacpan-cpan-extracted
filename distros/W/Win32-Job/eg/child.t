print STDERR "Child (pid=$$) (xxyyzz=$ENV{xxyyzz}) [STDERR]\n";
while (1) {
	wait unless defined fork;
	$y++ for (1 .. 1000_000);
	print "$$: $y [STDOUT]\n";
}
