use strict;
use Test::More;

BEGIN {
	use_ok $_ for qw(
		Ukigumo::Client
		Ukigumo::Client::Executor::Auto
		Ukigumo::Client::Executor::Callback
		Ukigumo::Client::Executor::Perl
		Ukigumo::Client::Executor::Prove
		Ukigumo::Client::Notify::Debug
		Ukigumo::Client::Notify::Ikachan
		Ukigumo::Client::Notify::GitHubStatuses
		Ukigumo::Client::Role::VC
		Ukigumo::Client::VC::Callback
		Ukigumo::Client::VC::Git
	);
}

done_testing;
