
BEGIN { $| = 1; print "1..1\n"; }

use Parse::ePerl;

$in = <<'EOT';
return "foo";
EOT
$rc = Parse::ePerl::Precompile({
    Script         => $in, 
	Result         => \$out
});
print STDERR @_;
if ($rc == 1 and &$out eq "foo") {
	print "ok 1\n";
}
else {
	print "not ok 1\n";
}

