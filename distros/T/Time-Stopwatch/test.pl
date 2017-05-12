# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use Time::Stopwatch;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print <<"NOTE" unless Time::Stopwatch::HIRES;

 ! As Time::HiRes could not be loaded, resolution will be !
 ! limited to one second.  Some tests will be skipped.    !

NOTE

# Does the timer work at all?
test2: {
    tie my $timer, 'Time::Stopwatch';
    my $start = $timer;
    sleep(1);
    my $stop = $timer;
    print $start < $stop ? "ok" : "not ok",
        " 2\t# $start < $stop\n";
};

# Can we supply an initial value?
test3: {
    tie my $timer, 'Time::Stopwatch', 32;
    my $stop = $timer;
    print $stop >= 32 ? "ok" : "not ok",
        " 3\t# $stop >= 32\n";
};

# How about assignment?
test4: {
    tie my $timer, 'Time::Stopwatch';
    $timer = 64;
    my $stop = $timer;
    print $stop >= 64 ? "ok" : "not ok",
        " 4\t# $stop >= 64\n";
};

# Are fractional times preserved?
test5: {
    tie my $timer, 'Time::Stopwatch', 2.5;
    my $stop = $timer;
    print $stop != int($stop) ? "ok" : "not ok",
        " 5\t# $stop != ${\int($stop)}\n";
};

# Can we do real fractional timing?
test6: {
    print "ok 6\t# skipped, no Time::HiRes\n"
	and next unless Time::Stopwatch::HIRES;
    tie my $timer, 'Time::Stopwatch', 1;
    select(undef,undef,undef,0.25);
    my $stop = $timer;
    print $stop != int($stop) ? "ok" : "not ok",
        " 6\t# $stop != ${\int($stop)}\n";
};

# Is it accurate to one second?
test7: {
    tie my $timer, 'Time::Stopwatch', 2;
    sleep(2);
    my $stop = $timer;
    print int($stop+.5) == 4 ? "ok" : "not ok",
        " 7\t# 3.5 <= $stop < 4.5\n";
};

# Is it accurate to 1/10 seconds?
test8: {
    print "ok 8\t# skipped, no Time::HiRes\n"
        and next unless Time::Stopwatch::HIRES;
    tie my $timer, 'Time::Stopwatch';
    select(undef,undef,undef,1.3);
    my $stop = $timer;
    print int(10*$stop+.5) == 13 ? "ok" : "not ok",
        " 8\t# 1.25 <= $stop < 1.35\n";
};

# Does $t++ really make the timer lag?
test9: {
    print "ok 9\t# skipped, no Time::HiRes\n"
        and next unless Time::Stopwatch::HIRES;
    tie my $timer, 'Time::Stopwatch';
    tie my $delay, 'Time::Stopwatch';
    while ($delay < 1) { $timer++; $timer--; }
    my $stop = $timer;
    print $stop < 1 ? "ok" : "not ok",
        " 9\t# $stop < 1 (confirms known bug)\n";
};

__END__


