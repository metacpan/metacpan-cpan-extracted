#!/usr/bin/perl -w
use strict;
use Text::JavE;

my $j2 = new Text::JavE;
while (my $file=shift @ARGV) {
	$j2->open_jmov($file);
	for (@{$j2->{frames}}) {
		system "cls";
		$_->display;
		my $time = $_->{msec};
		select (undef, undef, undef, $time/1000);
	}
}

