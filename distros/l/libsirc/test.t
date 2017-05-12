#!perl -w
use strict;

# $Id: test.t,v 1.6 2000-07-27 12:01:18-04 roderick Exp $
#
# Copyright (c) 1997-2000 Roderick Schertler.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

BEGIN {
    $| = 1;
    print "1..7\n";
}

use Sirc::Autoop ();
use Sirc::Chantrack ();
use Sirc::Kick ();
use Sirc::LckHash ();
use Sirc::LimitMan ();
use Sirc::Util;
use Sirc::URL;

sub test {
    my ($n, $result, @info) = @_;
    if ($result) {
    	print "ok $n\n";
    }
    else {
    	print "not ok $n\n";
	print "# ", @info, "\n" if @info;
    }
}

test 1, 1;

sub test_mask {
    my ($n, $in, $out) = @_;
    $out = "(?is)^$out\$";
    my $real = Sirc::Util::mask_to_re $in;
    test $n, $out eq $real, "mask_to_re($in) eq $real, expected $out";
}

test_mask 2, '', '';
test_mask 3, 'a', 'a';
test_mask 4, '+', '\\+';
test_mask 5, '*', '.*';
test_mask 6, '?', '.';
test_mask 7, '*!foo@*.bar.com', '.*\\!foo\\@.*\\.bar\\.com';
