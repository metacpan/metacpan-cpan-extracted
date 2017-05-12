#!/usr/bin/perl

BEGIN { $| = 1; print "1 .. 2\n"; }

END { print "Tests passed: $y/$num\n"; }

use Tie::DirHandle;

$num = 0;
sub TEST {
	$_[0] ? do { $y++, print "ok ", ++$num, "\n" } :
	do { $n++, print "not ok ", ++$num, "\n"; }
}

$ref = tie *FH, "Tie::DirHandle", *DH, "/tmp";
opendir TMP, "/tmp";

while (<FH>){ $tie .= $_; }
while (defined($_ = readdir TMP)){ $dir .= $_; }
TEST $tie eq $dir;

$ref->rewind;
rewinddir TMP;
$tie = scalar <FH>;
$dir = readdir TMP;
TEST $tie eq $dir;

untie *FH;
