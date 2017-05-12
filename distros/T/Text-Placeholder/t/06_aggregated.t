#!/usr/bin/perl -W -T

use strict;
use Test::Simple tests => 1;

use Text::Placeholder;
my $placeholder = Text::Placeholder->new(
	my $aggregator = '::Aggregator');
$aggregator->add_group(
	my $file_name = '::OS::Unix::File::Name',
	my $file_properties = '::OS::Unix::File::Properties',
	);
$placeholder->compile('[=file_name_full=] is owned by [=file_owner_name=]');

$aggregator->subject('/');
my $result = ${$placeholder->execute()};
ok($result eq '/ is owned by root', "T001: aggregated result");

exit(0);
