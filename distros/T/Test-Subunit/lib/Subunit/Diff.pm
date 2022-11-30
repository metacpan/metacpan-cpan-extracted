#!/usr/bin/perl
# Diff two subunit streams
# Copyright (C) 2009 Jelmer Vernooij <jelmer@samba.org>
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

package Test::Subunit::Diff;

use strict;

use Test::Subunit qw(parse_results);

sub control_msg() { }
sub report_time($$) { }

sub output_msg($$)
{
	my ($self, $msg) = @_;

	# No output for now, perhaps later diff this as well ?
}

sub start_test($$)
{
	my ($self, $testname) = @_;
}

sub end_test($$$$$)
{
	my ($self, $testname, $result, $unexpected, $reason) = @_;

	$self->{$testname} = $result;
}

sub new {
	my ($class) = @_;

	my $self = { 
	};
	bless($self, $class);
}

sub from_file($)
{
	my ($path) = @_;
	my $statistics = {
		TESTS_UNEXPECTED_OK => 0,
		TESTS_EXPECTED_OK => 0,
		TESTS_UNEXPECTED_FAIL => 0,
		TESTS_EXPECTED_FAIL => 0,
		TESTS_ERROR => 0,
		TESTS_SKIP => 0,
	};

	my $ret = new Test::Subunit::Diff();
	open(IN, $path) or return;
	parse_results($ret, $statistics, *IN);
	close(IN);
	return $ret;
}

sub diff($$)
{
	my ($old, $new) = @_;
	my $ret = {};

	foreach my $testname (keys %$old) {
		if ($new->{$testname} ne $old->{$testname}) {
			$ret->{$testname} = [$old->{$testname}, $new->{$testname}];
		}
	}

	return $ret;
}

1;
