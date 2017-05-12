# vi:fdm=marker fdl=0 syntax=perl:
# $Id: main.t,v 1.4 2002/01/30 03:59:52 jettero Exp $

use Test;
use Unix::Process;

plan tests => 2;

my $vsz = Unix::Process->vsz($$);    ok( $vsz  >0 );
my $pid = Unix::Process->pid;        ok( $pid, $$ );
