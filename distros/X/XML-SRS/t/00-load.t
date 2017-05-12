#!/usr/bin/perl -w

use strict;
use Test::More qw(no_plan);

use FindBin qw($Bin);
use File::Find;

my @modules;
my %uses;

finddepth(
	sub {
		m{^\w.*\.pm$} && do {
			my $module = $File::Find::name;
			$module =~ s{.*/lib.}{};
			$module =~ s{[/\\]}{::}g;
			$module =~ s{.pm$}{};
			push @modules, $module;
			open MODULE, "<", $_ or die "Failed to open ($_): $!";
			while (<MODULE>) {
				if (m{^use (\S+);}) {
					$uses{$module}{$1}++;
				}
				if (m{^(?:extends|with) (["'])?(\S+)\1}) {
					$uses{$module}{$2}++;
				}
			}
			close MODULE;
		};
	},
	"$Bin/../lib"
);

while ( my ($module, $uses) = each %uses ) {
	my @gonners;
	while ( my $dep = each %$uses ) {
		if ( not exists $uses{$dep} ) {
			push @gonners, $dep;
		}
	}
	delete $uses->{$_} for @gonners;
}

my %done;
while (@modules) {
	my (@winners) =
		grep { !$uses{$_} or !keys %{ $uses{$_} } } @modules;
	if ( !@winners ) {
		@winners = shift @modules;
	}
	for my $module ( sort @winners ) {
		my @fail;
		local ( $SIG{__WARN__} ) = sub {
			push @fail, join " ", @_;
			warn "# oh look a warning: @_";
		};
		use_ok($module);
		is( @fail, 0, "no warnings issued" );
		$done{$module}++;
		delete $uses{$module};
		delete $_->{$module} for values %uses;
	}
	@modules = grep { !$done{$_} } @modules;
}

# Copyright (C) 2007  Sam Vilain
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Artistic License 2.0 for more details.
#
# You should have received a copy of the Artistic License the file
# COPYING.txt.  If not, see
# <http://www.perlfoundation.org/artistic_license_2_0>
