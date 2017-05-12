#!/usr/bin/perl -W -T

use strict;

use Text::Placeholder;
my $placeholder = Text::Placeholder->new(
	my $counter = '::Counter');
$placeholder->compile('Counter: [=counter=]');

print ${$placeholder->execute()}, "<-\n";

exit(0);
