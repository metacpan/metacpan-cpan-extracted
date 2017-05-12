#!/usr/bin/perl -W -T

use strict;
use Test::Simple tests => 1;

use Text::Placeholder;
my $parser = Text::Placeholder::build_parser('^(.*?)<\%\s+([^\%\>]+)\s\%>');
my $placeholder = Text::Placeholder->new(
	$parser,
	my $counter = '::Counter');
$placeholder->compile('Counter: <% counter %>');

my $counter1 = ${$placeholder->execute()};
ok($counter1 eq 'Counter: 1', 'T001: plausibility');

exit(0);
