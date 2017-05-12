#!/usr/bin/perl

use strict;
use Test;
use Text::Diff;

my @A = map "$_\n", qw( 1 2 3 4 );
my @B = map "$_\n", qw( 1 2 3 5 );

sub _d($) {
	diff \@A, \@B, { OUTPUT => shift };
}

sub slurp {
	open SLURP, "<$_[0]" or die $!;
	my $string = join "", <SLURP>;
	close SLURP;
	return $string;
}

my $expected = _d undef;

my @tests = (
	sub {
		ok $expected =~ tr/\n//
	},
	sub {
		my $o;
		_d sub { $o .= shift };
		ok $o, $expected
	},
	sub {
		my @o;
		_d \@o;
		ok join( "", @o ), $expected;
	},
	sub {
		open F, ">output.foo" or die $!;
		_d \*F;
		close F or die $!;
		ok slurp "output.foo", $expected;
		unlink "output.foo" or warn $!;
	},
	sub {
		require IO::File;
		my $fh = IO::File->new( ">output.bar" );
		_d $fh;
		$fh->close;
		$fh = undef;
		ok slurp "output.bar", $expected;
		unlink "output.bar" or warn $!;
	},
	sub {
		ok 0 < index( diff( \"\n", \"", { STYLE => "Table" } ), "\\n" );
	},

	# Test for bug reported by Ilya Martynov <ilya@martynov.org> 
	sub {
		ok diff( \"", \"" ), "";
	},
	sub {
		ok diff( \"A", \"A" ), "";
	},
);

plan tests => scalar @tests;

$_->() for @tests;
