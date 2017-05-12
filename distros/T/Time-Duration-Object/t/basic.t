use Test::More tests => 15;
use strict;
use warnings;

BEGIN { use_ok('Time::Duration::Object'); }

{
	my $duration = Time::Duration::Object->new;
	is($duration, undef, "new requires arguments");
}

{
	my $duration = Time::Duration::Object->new(8000);
	isa_ok($duration, 'Time::Duration::Object');

	cmp_ok($duration->seconds, '==', 8000);
	is($duration->ago_exact, '2 hours, 13 minutes, and 20 seconds ago');

	is(
	  $duration->ago_exact->as_string,
	  '2 hours, 13 minutes, and 20 seconds ago',
	);

	is($duration->ago, '2 hours and 13 minutes ago');
	isa_ok($duration->ago, 'Time::Duration::_Result');
	can_ok($duration->ago, 'concise');
	#is($duration->ago->concise, '2 hours and 13 minutes ago');

	my $ago = $duration->ago;
	is($ago, '2 hours and 13 minutes ago');
	isa_ok($ago, 'Time::Duration::_Result');
	can_ok($ago, 'concise');
	is($ago->concise, '2h13m ago');
}

{
  my $duration = Time::Duration::Object->new(87000);
  is($duration->ago, '1 day and 10 minutes ago');
  is($duration->ago(1), '1 day ago');
}
