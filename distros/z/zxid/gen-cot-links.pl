#!/usr/bin/perl
# Copyright (c) 2006 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
# This is confidential unpublished proprietary source code of the author.
# NO WARRANTY, not even implied warranties. Contains trade secrets.
# Distribution prohibited unless authorized in writing. See file COPYING.
# $Id: gen-cot-links.pl,v 1.2 2009-08-30 15:09:26 sampo Exp $
# 30.9.2006, created --Sampo
#
# Generate symlinks in the /var/zxid/cot directory
# Usage: cd /var/zxid/cot; ~/zxid/gen-cot-links.pl *

undef $/;
for $f (@ARGV) {
    open F, "<$f" or die "Can't read($f): $!";
    $x = <F>;
    close F;
    ($eid) = $x =~ /entityID="(.+?)"/;
    if (!$eid) {
	warn "Couldn't determine entityID for file($f). Skipped.";
	next;
    }
    $eid =~ s%[/?]%_%g;
    symlink $f, ".$eid";
}

#EOF
