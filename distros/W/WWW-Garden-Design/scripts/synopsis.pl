#!/usr/bin/env perl

use 5.30.0;
use strict;
use warnings;

use MojoX::Validate::Util;

# ------------------------------------------------
# This is a copy of t/01.range.t, without the Test::More parts.

my(%count)		= (pass => 0, total => 0);
my($checker)	= MojoX::Validate::Util -> new;
my(%expected)	= (pass => 7, total => 9);

$checker -> add_dimension_check;

my(@data) =
(
	{height => ''},				# Pass.
	{height => '1'},			# Fail. No unit.
	{height => '1cm'},			# Pass.
	{height => '1 cm'},			# Pass.
	{height => '1m'},			# Pass.
	{height	=> '40-70.5cm'},	# Pass.
	{height	=> '1.5-2m'},		# Pass.
	{height => 'z1'},			# Fail. Invalid unit.
);

my($expected);
my($infix);

for my $params (@data)
{
	$count{total}++;

	$count{pass}++ if ($checker -> check_dimension($params, 'height', ['cm', 'm']) == 1);
}

$count{total}++;

$count{pass}++ if ($checker -> check_optional({x => ''}, 'x') == 1);

say "Expected counts: \n", join("\n", map{"$_: $expected{$_}"} sort keys %expected);
say "Test counts: \n", join("\n", map{"$_: $count{$_}"} sort keys %count);
