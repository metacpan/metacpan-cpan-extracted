#!/usr/bin/perl

# $Id: Versions.pm,v 1.9 2003/08/24 22:58:14 ed Exp $

# Copyright (c) 1996, Kenneth J. Albanowski. All rights reserved.  This
# program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.

package Sort::Versions;
use vars '$VERSION';
$VERSION = '1.5';

require Exporter;
@ISA=qw(Exporter);

@EXPORT=qw(&versions &versioncmp);
@EXPORT_OK=qw();

sub versioncmp( $$ ) {
    my @A = ($_[0] =~ /([-.]|\d+|[^-.\d]+)/g);
    my @B = ($_[1] =~ /([-.]|\d+|[^-.\d]+)/g);

    my ($A, $B);
    while (@A and @B) {
	$A = shift @A;
	$B = shift @B;
	if ($A eq '-' and $B eq '-') {
	    next;
	} elsif ( $A eq '-' ) {
	    return -1;
	} elsif ( $B eq '-') {
	    return 1;
	} elsif ($A eq '.' and $B eq '.') {
	    next;
	} elsif ( $A eq '.' ) {
	    return -1;
	} elsif ( $B eq '.' ) {
	    return 1;
	} elsif ($A =~ /^\d+$/ and $B =~ /^\d+$/) {
	    if ($A =~ /^0/ || $B =~ /^0/) {
		return $A cmp $B if $A cmp $B;
	    } else {
		return $A <=> $B if $A <=> $B;
	    }
	} else {
	    $A = uc $A;
	    $B = uc $B;
	    return $A cmp $B if $A cmp $B;
	}	
    }
    @A <=> @B;
}

sub versions() {
    my $callerpkg = (caller)[0];
    my $caller_a = "${callerpkg}::a";
    my $caller_b = "${callerpkg}::b";
    no strict 'refs';
    return versioncmp($$caller_a, $$caller_b);
}

1;

