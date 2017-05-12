# Fetch test (Online)
use Test::More;
use strict;
use warnings;
use utf8;

use WebService::Zusaar;

use DateTime::Format::ISO8601;

# Prepare the Expected patterns (It's same as a part of item values of Test API response)
my @expect_patterns = (
	{
		owner_nickname => '__papix__',
		catch => '囲め! ゆーすけべーさん!!',
		event_id => '489104'
	},
	{
		owner_nickname => 'Kansai Perl Mongers',
		catch => '関西のPerlユーザーによる、Perlユーザーのための集会',
		event_id => '476003'
	},
);

my $expect_patterns_i = 0;

# Initialize a instance
my $obj = WebService::Zusaar->new();
# Fetch events
$obj->fetch('event', keyword => 'Kansai.pm');

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