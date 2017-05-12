#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 03-denied.t 28 2014-07-31 15:30:31Z minus $
#
#########################################################################
use Test::More tests => 6;
use File::Temp qw/ tempdir /;
use WWW::MLite::AuthSsn;
my $dir = tempdir( CLEANUP => 1 );
my $usid = undef;
my $ssn = new WWW::MLite::AuthSsn(
    -dsn  => "driver:file",
    -sid  => $usid,
    -args => {Directory => $dir},
);
is($ssn->status, 0, "Start status");
is($ssn->reason, "AUTH_REQUIRED", "Start reason");
is($ssn->access, 0, "Access denied");
is($ssn->delete, 1, "Session delete");
is($ssn->status, 0, "Finish status");
is($ssn->reason, "UNAUTHORIZED", "Finish reason");
1;
