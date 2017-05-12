
BEGIN { $| = 1; print "1..1\n"; }

use Parse::ePerl;

open(TMP, ">tmpfile");
print TMP <<'EOT';
bar
EOT
close(TMP);

$in = <<'EOT';
foo
#include tmpfile
quux
EOT

$test = <<'EOT';
foo
bar
quux
EOT

$rc = Parse::ePerl::Preprocess({
    Script  => $in, 
	Result  => \$out,
	INC     => [ 'One', '.', 'Three' ]
});

if ($rc == 1 and $out eq $test) {
	print "ok 1\n";
}
else {
	print "not ok 1\n";
}

unlink("tmpfile");

