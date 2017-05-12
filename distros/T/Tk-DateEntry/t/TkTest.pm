# Copyright (C) 2003,2006,2007 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# Code taken from Tk's t/TkTest.pm

package # make sure it's never indexed by PAUSE
    TkTest;

use strict;
use vars qw(@EXPORT_OK $VERSION);
$VERSION = '1.00';

use base qw(Exporter);
@EXPORT_OK = qw(catch_grabs);

sub catch_grabs (&$) {
    my($code, $tests) = @_;
    my $ok = 1;
    my $tests_before = Test::More->builder->current_test;
    eval {
	$code->();
    };
    if ($@) {
	if ($@ !~ m{^grab failed: (window not viewable|another application has grab)}) {
	    die $@;
	} else {
	    Test::More::diag("Ignore grab problem: $@");
	    $ok = 0;
	}
    }
    my $tests_after = Test::More->builder->current_test;
    if ($tests_after - $tests_before != $tests) {
	for (1 .. $tests - ($tests_after - $tests_before)) {
	    Test::More::pass("Ignore test because other application had grab");
	}
    }
    $ok;
}

1;
