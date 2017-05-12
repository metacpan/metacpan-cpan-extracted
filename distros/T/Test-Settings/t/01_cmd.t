#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Settings qw(:all);

use Config;
use File::Temp qw(tempfile);

# Find perl binary
my $perlbin;
eval "require Probe::Perl";
unless ($@) {
        $perlbin = Probe::Perl->find_perl_interpreter();
}
$perlbin ||= $Config{perlpath};

# Clean up our state
disable_all();

# Sanity
my $output = _run(<<EOF, '');
use strict;
use Test::More;
use Test::Settings qw(:all);

is(want_smoke(), undef, 'smoke is disabled');
EOF

unlike($output, qr/failed/i, "smoke is disabled");

# Test each kind
for my $k (qw(smoke extended author release non_interactive all)) {
	my $output = _run(<<EOF, "$k");
use strict;
use Test::More;
use Test::Settings qw(:all);

is(want_$k(), 1, "want_$k is true");

ok(1, "Ran a test dude");

done_testing;
EOF
	unlike($output, qr/failed/i, "Test succeeded with $k");
}

enable_all();

# Sanity
$output = _run(<<EOF, '');
use strict;
use Test::More;
use Test::Settings qw(:all);

is(want_smoke(), 1, 'smoke is enabled');
EOF

unlike($output, qr/failed/i, "smoke is enabled");

for my $k (qw(smoke extended author release non_interactive all)) {
	my $flag = $k;
	if ($flag eq 'all') {
		$flag = 'none';
	} else {
		$flag = "no_$flag";
	}

	my $output = _run(<<EOF, $flag);
use strict;
use Test::More;
use Test::Settings qw(:all);

is(want_$k(), undef, "want_$k is false");

ok(1, "Ran a test dude");

done_testing;
EOF
	unlike($output, qr/failed/i, "Test succeeded with $k");
}

# Test two settings
disable_all();

$output = _run(<<EOF, 'all,no_smoke');
use strict;
use Test::More;
use Test::Settings qw(:all);

is(want_author(), 1, 'want author');
is(want_smoke(), undef, 'do not want smoke');

done_testing;
EOF

unlike($output, qr/failed/i, 'Multiple flags work');

sub _run {
	my ($program, $opt) = @_;

	my ($fh, $name) = tempfile;

	print $fh $program;

	close($fh);

	my $output = `$perlbin -MTest::S=$opt $name 2>&1`;

	close($fh);

	unlink($name);

	return $output;
}


done_testing;
