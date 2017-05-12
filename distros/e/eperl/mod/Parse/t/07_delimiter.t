
BEGIN { $| = 1; print "1..3\n"; }

use Parse::ePerl;

$in = <<'EOT';
foo
<ePerl> print "bar"; </ePerl>
quux
EOT
$test = <<'EOT';
foo
bar
quux
EOT
$rc = Parse::ePerl::Expand({
	Script         => $in,
	Result         => \$out,
	BeginDelimiter => "<ePerl>", 
	EndDelimiter   => "</ePerl>"
});
if ($rc == 1 and $out eq $test) {
    print "ok 1\n";
}
else {
    print "not ok 1\n";
}
$rc = Parse::ePerl::Expand({
	Script         => $in,
	Result         => \$out,
	BeginDelimiter => "<eperl>", 
	EndDelimiter   => "</eperl>",
	CaseDelimiters => 0
});
if ($rc == 1 and $out eq $test) {
    print "ok 2\n";
}
else {
    print "not ok 2\n";
}
$rc = Parse::ePerl::Expand({
	Script         => $in,
	Result         => \$out,
	BeginDelimiter => "<eperl>", 
	EndDelimiter   => "</eperl>",
	CaseDelimiters => 1
});
if ($rc == 1 and $out ne $test) {
    print "ok 3\n";
}
else {
    print "not ok 3\n";
}

