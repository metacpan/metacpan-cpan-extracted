# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use Ogg::Vorbis;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Test general information functions
$current_section = -1;
$buffer = 'x' x 4096;
#eval { $endian = Ogg::Vorbis::host_is_big_endian() };
#if ($@) { die "not ok 2\n";} else { print "ok 2\n"; }
print "ok 2\n";

# Test object creation
eval { $ogg = Ogg::Vorbis->new };
if ($@) { die "not ok 3\n";} else { print "ok 3\n"; }

# Test stream opening
open(INPUT, "test.ogg") || die "Couldn't open input file\n";
if ($ogg->open(INPUT) <0) {
  die "not ok 4\n";
} else {
  print "ok 4\n"
}

# Test stream specific info
eval { $ogg->streams() };
if ($@) { die "not ok 5\n";} else { print "ok 5\n"; }

eval { $ogg->time_total() };
if ($@) { die "not ok 6\n";} else { print "ok 6\n"; }

# Test Ogg::Vorbis::Info
eval { $info = $ogg->info() };
if ($@) { die "not ok 7\n";} else { print "ok 7\n"; }

eval { $info->channels() };
if ($@) { die "not ok 8\n";} else { print "ok 8\n"; }

# Test the comments
eval { %comments = %{$ogg->comment()} };
if ($@) { die "not ok 9\n";} else { print "ok 9\n"; }
eval { keys %comments };
if ($@) { die "not ok 10\n";} else { print "ok 10\n"; }

# Test read
eval { $ogg->read($buffer, 4096, $endian, 2, 1, $current_section) };
if ($@) { die "not ok 11\n";} else { print "ok 11\n"; }

# Test clear
eval { $ogg->clear() };
if ($@) { die "not ok 12\n";} else { print "ok 12\n"; }

close(INPUT);
