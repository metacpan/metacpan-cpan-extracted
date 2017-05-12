#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 1999-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test;

BEGIN { plan tests => 9 }
BEGIN { require "./t/test_utils.pl"; }

use Unix::Processors;
ok(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# 2: Constructor
my $procs = new Unix::Processors();
ok ($procs);

# 3: Max online
my $online = $procs->max_online;
print "Cpu threads online: $online\n";
ok($online);

# 4: Max physical
my $phys = $procs->max_physical;
print "Physical cpu cores: $phys\n";
ok($phys);

# 5: Max socket
my $socks = $procs->max_socket;
print "Physical cpu sockets: $socks\n";
ok($socks);

# 6: Max speed
my $clock = $procs->max_clock;
print "Cpu frequency: $clock\n";
ok($online);

# 7: Procs state
my $proclist = $procs->processors;
ok($proclist);

# 8: Procs owner
my $ok=1;
foreach my $proc (@{$procs->processors}) {
    $ok = 0 if (!$proc->state || !$proc->type);
    printf +("Id %s  State %s  Clock %s  Type %s\n",
	     $proc->id, $proc->state, $proc->clock, $proc->type);
}
ok($ok);

# 9: Destructor
undef $procs;
ok(1);

