#!/usr/bin/env perl

use lib 'lib';
use strict;
use warnings;

use Test::More;

use MojoX::Validate::Util;

# ------------------------------------------------

my($test_count)	= 0;
my($checker)	= MojoX::Validate::Util -> new;

my(@data) =
(
	{height => ''},				# Pass.
	{height => '1'},			# Fail. No unit.
	{height => '1cm'},			# Pass.
	{height => '1 cm'},			# Pass.
	{height => '1m'},			# Pass.
	{height	=> '40-70.5cm'},	# Pass.
	{height	=> '1.5-2m'},		# Pass.
	{height => 'z1'},			# Fail.
);

my($expected);
my($infix);
my($message);

for my $params (@data)
{
	$expected	= ($$params{height} =~ /^z?1$/) ? 0 : 1;
	$infix		= $expected ? '' : 'not ';
	$message	= "Height '$$params{height}' is ${infix}a valid height";

	ok($checker -> check_dimension($params, 'height', ['cm', 'm']) == $expected, $message); $test_count++;
}

print "# Internal test count: $test_count\n";

done_testing($test_count);
