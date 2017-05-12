#!/usr/bin/perl -W -T

use strict;
use Test::Simple tests => 1;

use Text::Placeholder;
my $placeholder = Text::Placeholder->new(
	my $generic = '::Generic');
$generic->add_placeholder('some_value', sub { return((time()%86400)) });

$placeholder->compile('Some value: [=some_value=]');
my $result = ${$placeholder->execute()};

ok($result =~ m/Some value: \d+$/, "Returned '$result'");

exit(0);
