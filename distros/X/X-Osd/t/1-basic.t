# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
my $CVS_VERSION = sprintf '%s', q$Revision: 1.4 $ =~ /: ([0-9.]*)/;
######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END { print "not ok 1\n" unless $loaded; }
use X::Osd;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
my $osd;

my $test_count = 2;
my $usleep     = 400;

eval {
	$osd = X::Osd->new(2);
};

print(($@ ? 'not ok' : 'ok'), ' ', ($test_count++), "\n");

eval {
    $osd->string(0, 'Hello World!');
    sleep 1;
};

print(($@ ? 'not ok' : 'ok'), ' ', ($test_count++), "\n");

	eval {
    foreach my $num (0 .. 10)
    {
        $osd->slider(0, ($num * 10));
        delay();
    }
    sleep 1;
	};

print(($@ ? 'not ok' : 'ok'), ' ', ($test_count++), "\n");

	eval {
    foreach my $num (0 .. 10)
    {
        $osd->percentage(0, ($num * 10));
        delay();
    }
    sleep 1;
	};

print(($@ ? 'not ok' : 'ok'), ' ', ($test_count++), "\n");

eval {
	$osd->set_colour(red);
	$osd->string(0, 'Red test line 1');
	delay();
	$osd->string(1, 'Red test line 2');
	delay();
};

print(($@ ? 'not ok' : 'ok'), ' ', ($test_count++), "\n");

eval {
	$osd->set_align(XOSD_center);
	$osd->set_timeout(10000000);
	$osd->string(1, 'Middle alignment test 1');
	delay();
	$osd->scroll(1);
	delay();
};

print(($@ ? 'not ok' : 'ok'), ' ', ($test_count++), "\n");

eval {
	$osd->set_shadow_offset(4);
	$osd->string(1, 'Shadow colour test 1');
	delay();
	$osd->set_shadow_colour(green);
	$osd->string(2, 'Shadow colour test 2');
	delay();
};

print(($@ ? 'not ok' : 'ok'), ' ', ($test_count++), "\n");

eval {
	$osd->set_pos(XOSD_middle);
	$osd->string(1, 'Center alignment test');
	delay();
};

print (($@ ? 'not ok' : 'ok'), ' ', ($test_count++), "\n");

eval {
	$osd->set_shadow_offset(0);
	$osd->set_outline_colour(blue);
	$osd->set_outline_offset(2);
	$osd->string(1, 'Outline colour and offset test 1');
	delay(1);
	$osd->set_outline_offset(4);
	$osd->string(2, 'Outline colour and offset test 2');
	delay(1);
};

print (($@ ? 'not ok' : 'ok'), ' ', ($test_count++), "\n");

sub delay
{
    my $delay = shift || 0.25;
    select(undef, undef, undef, $delay);
}
