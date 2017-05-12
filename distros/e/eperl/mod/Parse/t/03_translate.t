
BEGIN { $| = 1; print "1..1\n"; }

use Parse::ePerl;

$in = <<'EOT';
foo
<: print "bar"; :>
quux
EOT
$test = <<'EOT';
print "foo\n";
print "bar"; print "\n";
print "quux\n";
EOT
$rc = Parse::ePerl::Translate({
    Script         => $in, 
	Result         => \$out,
	BeginDelimiter => "<:",
	EndDelimiter   => ":>"
});
if ($rc == 1 and $out eq $test) {
	print "ok 1\n";
}
else {
	print "not ok 1\n";
}

