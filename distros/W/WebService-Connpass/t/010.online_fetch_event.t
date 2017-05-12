# Fetch test (Online)
use Test::More;
use strict;
use warnings;
use utf8;

use WebService::Connpass;

use DateTime::Format::ISO8601;

# Prepare the Expected patterns (It's same as a part of item values of Test API response)
my @expect_patterns = (
	{
		title => '#Perl鍋 #1',
		event_id => '1613',
		started => DateTime::Format::ISO8601->new()->parse_datetime('2013-01-17T19:00:00+09:00'),
		started_at => '2013-01-17T19:00:00+09:00',
	},
);

my $expect_patterns_i = 0;

# Initialize a instance
my $obj = WebService::Connpass->new();
# Fetch events
$obj->fetch('event', event_id => '1613');

# Iterate a fetched events
while(my $event = $obj->next) {
	# Compare values of item, with Expected pattern
	my $ptn = $expect_patterns[$expect_patterns_i];
	foreach(keys %$ptn){
		is($event->$_, $ptn->{$_}, "Item > $_");
	}
	$expect_patterns_i += 1;
}

# Reverse iterate a fetched events
$expect_patterns_i = @expect_patterns - 1;
while(my $event = $obj->prev) {
	# Compare values of item, with Expected pattern
	my $ptn = $expect_patterns[$expect_patterns_i];
	foreach(keys %$ptn){
		is($event->$_, $ptn->{$_}, "Item > $_");
	}
	$expect_patterns_i -= 1;
}

# End
done_testing;