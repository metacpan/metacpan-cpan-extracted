# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use MP3::Tag;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#test 2,3 - getting the tags
$mp3 = MP3::Tag->new("test.mp3");
$mp3->getTags;

$v1 = $mp3->{ID3v1};
ok($v1," 2 Detecting ID3v1");

$v2 = $mp3->{ID3v2};
ok($v2," 3 Detecting ID3v2");

#test 4 - reading ID3v1
ok(($v1 && ($v1->song eq "Song") && ($v1->track == 10))," 4 Reading ID3v1");

#test 5 - reading ID3v2
ok($v2 && $v2->getFrame("COMM")->{short} eq "Test!"," 5 Reading ID3v2");

#test 6,7 - writing ID3v1
ok($v1 && $v1->song("New")," 6 Changing ID3v1");
ok($v1 && $v1->writeTag," 7 Writing ID3v1");

#test 8,9 - writing ID3v2
ok($v2 && $v2->add_frame("TLAN","ENG")," 8 Changing ID3v2");
ok($v2 && $v2->write_tag," 9 Writing ID3v2");

$mp3 = MP3::Tag->new("test.mp3");
$mp3->getTags;
$v1 = $mp3->{ID3v1};
$v2 = $mp3->{ID3v2};

#test 10 - reading ID3v1
ok($v1 && $v1->song eq "New","10 Checking new ID3v1");

#test 11 - reading ID3v2
ok($v2 && $v2->getFrame("TLAN") eq "ENG","11 Checking new ID3v2");

#back to original tag
if ($v1 && $v1->song eq "New") {
  $v1->song("Song");
  $v1->writeTag;  
}
if ($v2 && $v2->getFrame("TLAN") eq "ENG") {
  $v2->remove_frame("TLAN");
  $v2->write_tag;
}

sub ok {
  my ($result, $test) = @_;
  print "Test $test", '.' x (28-length($test));
  print " not" unless $result;
  print " ok\n";
}
