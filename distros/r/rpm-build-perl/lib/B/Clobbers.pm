package B::Clobbers;
our $VERSION = '0.01';

use strict;
use B::Walker qw(padval walk);
use B qw(ppname OPpLVAL_INTRO);

our @vars = qw(_ / , \ ");
our %vars = map { $_ => 1 } @vars;
our $Verbose = 0;

sub do_gvsv ($) {
	my $op = shift;
	my $var = padval($op->padix)->SAFENAME;
	return unless $vars{$var};
	if ($op->private & OPpLVAL_INTRO) {
		$B::Walker::BlockData{$var} = 1;
		print STDERR "local \$$var at $0 line $B::Walker::Line\n" if $Verbose;
	}
	elsif ($op = $op->next and $$op and $op->name eq "sassign") {
		return if $B::Walker::BlockData{$var};
		print "\t*** \$$var clobbered at $0 line $B::Walker::Line\n";
	}
}

sub do_rv2gv ($) {
	my $op = shift;
	my $gv = $op->first;
	return unless $gv->name eq "gv";
	my $var = padval($gv->padix)->SAFENAME;
	return unless $vars{$var};
	if ($op->private & OPpLVAL_INTRO) {
		$B::Walker::BlockData{$var} = 1;
		print STDERR "local \*$var at $0 line $B::Walker::Line\n" if $Verbose;
	}
	elsif ($op = $op->next and $$op and $op->name eq "sassign") {
		return if $B::Walker::BlockData{$var};
		print "\t*** \*$var clobbered at $0 line $B::Walker::Line\n";
	}
}

sub do_readline ($) {
	my $op = shift;
	$op = $op->next;
	$op = $op->first while ref($op) eq "B::UNOP";
	return unless $op->name eq "gvsv";
	my $var = padval($op->padix)->SAFENAME;
	return unless $vars{$var};
	return if $B::Walker::BlockData{$var};
	print "\t*** \$$var clobbered at $0 line $B::Walker::Line\n";
}

sub do_enteriter ($) {
	my $op = shift;
	my $op = $op->first->sibling->sibling;
	return unless $$op;
	$op = $op->first if $op->name eq "rv2gv";
	return unless $op->name eq "gv";
	my $gv = ref($op) eq "B::PADOP" ? padval($op->padix) : $op->gv;
	my $var = $gv->SAFENAME;
	return unless $vars{$var};
	print STDERR "implicitly localized \$$var at $0 line $B::Walker::Line\n" if $Verbose;
	$B::Walker::BlockData{_} = 1;
}

%B::Walker::Ops = (
	gvsv		=> \&do_gvsv,
	rv2gv		=> \&do_rv2gv,
	readline	=> \&do_readline,
	enteriter	=> \&do_enteriter,
	grepwhile	=> sub { $B::Walker::BlockData{_} = 1 },
	mapwhile	=> sub { $B::Walker::BlockData{_} = 1 },
);

sub compile {
	my $pkg = __PACKAGE__;
	for my $opt (@_) {
		$opt =~ /^-(?:v|-?verbose)$/ and ++$Verbose or
		die "$pkg: unknown option: $opt\n";
	}
	return sub {
		local $| = 1;
		local $SIG{__DIE__} = sub {
			print STDERR "Dying at $0 line $B::Walker::Line\n";
			require Carp;
			Carp::cluck();
		};
		walk();
	}
}

1;

__END__

=head1	NAME

B::Clobbers - clobbering analyzer

=head1	COPYING

Copyright (c) 2007 Alexey Tourbin, ALT Linux Team.

This is free software; you can redistribute it and/or modify it under the terms
of the GNU General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later version.

