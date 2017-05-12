# Verify that perl executes concurrently as it should under MULTI_PERL

import perl
if not perl.MULTI_PERL:
        print "1..0"
        raise SystemExit

print "1..10"

import thread
import time

def t(start, step, stop):
    perl.eval("""

    my($start, $step, $stop) = (%d,%d,%d);

    $| = 1;
    for (my $i = $start; $i <= $stop; $i += $step) {
        print "ok $i\n";
        sleep(1);
    }
    
    """ % (start, step, stop))

thread.start_new_thread(t, (1, 2, 9))
time.sleep(0.5)
thread.start_new_thread(t, (2, 2, 10))

perl.eval("sleep 3")
print "perl sleep done"
time.sleep(4)
print "done"
