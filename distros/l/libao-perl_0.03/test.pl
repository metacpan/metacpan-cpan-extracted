# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use Ao;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$chunk = 2;
if ($ao_id = Ao::get_driver_id("NULL")) {
#  print "  Ao::get_driver_id(\"NULL\") = $ao_id\n";
  print "ok $chunk\n";
} else {
  die "not ok $chunk\n";
}

# Test constants
$chunk++;
if (AO_OSS) {
#  print "AO_OSS = ", Ao::AO_OSS, "\n";
  print "ok $chunk\n";
} else {
  die "not ok $chunk\n";
}

# Test info
$chunk++;
if (%ao_info = %{Ao::get_driver_info($ao_id)}) {
#  while (($k, $v) = each(%ao_info)) {
#    print "$k => $v\n";
#  }
  print "ok $chunk\n";
} else {
  die "not ok $chunk\n";
}

$chunk++;
if ($ao_out = Ao::open($ao_id)) {
#  print "  Ao::open($ao_id)\n";
  print "ok $chunk\n";
} else {
  die "not ok $chunk\n";
}

$chunk++;
if (Ao::play($ao_out,"X",0) == 0) {
#  print "  Ao::play(\$ao_out,\"X\",0)\n";
  print "ok $chunk\n";
} else {
  die "not ok $chunk\n";
}

$chunk++;
if (Ao::close($ao_out) == 0) {
#  print "  Ao::close(\$ao_out)\n";
  print "ok $chunk\n";
} else {
  die "not ok $chunk\n";
}

# Now try OO-interface

$chunk++;
if ($ao_id = Ao::get_driver_id("NULL")) {
#  print "  Ao::get_driver_id(\"NULL\") = $ao_id\n";
  print "ok $chunk\n";
} else {
  die "not ok $chunk\n";
}

$chunk++;
%options = ("file" => "out.wav");
if ($ao_out = Ao::open($ao_id, 16, 44100, 2, \%options)) {
#  print "  Ao::open($ao_id)\n";
  print "ok $chunk\n";
} else {
  die "not ok $chunk\n";
}

$chunk++;
if ($ao_out->play("X",0) == 0) {
#  print "  \$ao_out->play(\"X\",0)\n";
  print "ok $chunk\n";
} else {
  die "not ok $chunk\n";
}

$chunk++;
if ($ao_out->close() == 0) {
#  print "  \$ao_out->close()\n";
  print "ok $chunk\n";
} else {
  die "not ok $chunk\n";
}
