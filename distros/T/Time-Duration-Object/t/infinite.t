use Test::More tests => 14;
use strict;
use warnings;

BEGIN { use_ok('Time::Duration::Object::Infinite'); }

{
	my $duration = Time::Duration::Object::Infinite->new;
	isa_ok($duration, 'Time::Duration::Object');
	isa_ok($duration, 'Time::Duration::Object::Infinite');
	
	is($duration->ago_exact, 'forever ago');

	is($duration->ago, 'forever ago');
	can_ok($duration->ago, 'concise');
	is($duration->ago->concise, 'forever ago');

	is($duration->later, 'infinitely later');
	is($duration->earlier, 'infinitely earlier');
}

{
  my $duration = Time::Duration::Object::Infinite->new_negative;
  is($duration->ago, 'forever from now');
  is($duration->ago->as_string, 'forever from now');
  is($duration->ago(1), 'forever from now');
  is($duration->later, 'infinitely earlier');
  is($duration->earlier, 'infinitely later');
}
