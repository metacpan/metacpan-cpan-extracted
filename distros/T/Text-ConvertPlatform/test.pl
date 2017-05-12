# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::ConvertPlatform;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# Ok, I'll put some darn tests in here

srand();
for ($i = 0; $i < 10000; $i++) {
	$test_blob .= pack 'S', rand 0xffff;
	}
$test_num = 2;	

eval {
	open F, '>xx' or die "couldn't create: $!";
	print F $test_blob;

	if ($philip = new Text::ConvertPlatform) {
		print "ok ", $test_num++, "\n";
		}
	else {
		print "NOT ok ", $test_num++, "\n";
		}
	if ($philip->filename("xx")) {
		print "ok ", $test_num++, "\n";
		}
	else {
		print "NOT ok ", $test_num++, "\n";
		}
	if ($philip->convert_to("mac")) {
		print "ok ", $test_num++, "\n";
		}
	else {
		print "NOT ok", $test_num++, "\n";
		}
	if ($philip->process_file) {
		print "ok ", $test_num++, "\n";
		}
	else {
		print "NOT ok", $test_num++, "\n";
		}
	if ($philip->replace_file) {
		print "ok ", $test_num++, "\n";
		}
	else {
		print "NOT ok", $test_num++, "\n";
		}
	if ($philip->backup_file) {
		print "ok ", $test_num++, "\n";
		}
	else {
		print "NOT ok", $test_num++, "\n";
		}

	if ($@) {
		print "... error: $@\n";
		}

	unlink glob 'xx*';

	};

print "Mares eat oats and does eat oats but little lambs eat ivy.\n";
print "A kid would eat ivy too, wouldn't you?\n";
print "ok 13\n";
