use Test::More 1.00;

BEGIN { use_ok "Test::Prereq" }

subtest no_ignore => sub {
	my @ignore = ();
	my $rc = prereq_ok( undef, undef, \@ignore );
	};

done_testing();
