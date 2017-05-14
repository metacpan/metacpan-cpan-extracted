#!/usr/bin/perl -I../p
# Copyright (c) 1998-1999 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
# This software may not be used or distributed for free or under any other
# terms than those detailed in file COPYING. There is ABSOLUTELY NO WARRANTY.

# Slurp and barf files with flock. These are supposed to be reasonably
# efficient, too. Stdio is bypassed, for example.

package filex;
use integer;

$trace = 0;

sub slurp {
    my ($t,$nowarn) = @_;
    if (open(T, "<$t")) {
	flock T, 1; # Shared
	sysseek(T, 0, 0);
	sysread T, $t, -s(T);
	flock T, 8;
	close T;
	return $t;
    } else {
	my ($p,$f,$l)=caller;
	warn "$$: Cant read `$t' ($! at $f line $l)\n" unless $nowarn;
	return undef;
    }
}

sub barf {
    my ($t, $d) = @_;
    my ($p,$f,$l)=caller;
    umask 002;
    ($t) = $t =~ /^([^|;:&]+)$/;  # untaint
    warn "$$: Barfing $t at $f line $l\n" if $trace;
    if (open(T, ">$t")) {
	flock T, 2; # Exclusive
	sysseek(T, 0, 0);
	syswrite T, $d, length($d);  # Bypass stdio for efficiency
	flock T, 8;
	close T or do {
	    warn "$$: Cant write `$t' ($! at $f line $l)\n";
	    return undef;
	};
	return length($d)
    } else {
	warn "$$: Cant write `$t' ($! at $f line $l)\n";
	return undef;
    }
}

### This is really a multitasking synchronization primitive, useful
### for maintaining unique numbers.

sub inc {
    my ($t,$inc) = @_;
    if (open(T, "+<$t")) {
	flock T, 2; # Exclusive
	
	seek(T, 0, 0);
	$t = <T>;
	chomp $t;
	seek(T, 0, 0);	
	if ($inc eq 'a') {
	    print T ++$t;
	} else {
	    print T $t + $inc;
	}
	truncate T, tell T;
	
	flock T, 8;
	close T;
	return $t;
    } else {
	my ($p,$f,$l)=caller;
	warn "$$: Cant update `$t' ($! at $f line $l)";
	return '';
    }
}

### Safely add a line to log

sub append {
    my ($t,$line) = @_;
    if (open(T, ">>$t")) {
	flock T, 2; # Exclusive
	
	seek(T, 0, 2);   # Go to absolute end of file (someone could have
	                 # written to the file while we were waiting for
	                 # flock)
	print T $line;
	flock T, 8;
	close T;
	return 1;
    } else {
	my ($p,$f,$l)=caller;
	warn "$$: Cant append `$t' ($! at $f line $l)";
	return 0;
    }
}

1;

# EOF
