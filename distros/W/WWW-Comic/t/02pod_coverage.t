use Test::More;

eval "use Test::Pod::Coverage 1.00";
if ($@) {
	plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD Coverage";
} else {
	my @tests = Test::Pod::Coverage::all_modules();
	plan tests => ($#tests+1);
}

for my $module (Test::Pod::Coverage::all_modules()) {
	if ($module =~ /::Plugin::\w+/) {
		pod_coverage_ok($module, {
				also_private => [ qr/^[A-Z_]+$/ ], # Ignore all caps
				trustme => [qr/^(new|strip_url|mirror_strip|comics|get_strip)$/],
			});
	} else {
		pod_coverage_ok($module, {
				also_private => [ qr/^[A-Z_]+$/ ], # Ignore all caps
			});
	}
}

