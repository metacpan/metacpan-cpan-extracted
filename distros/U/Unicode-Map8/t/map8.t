print "1..18\n";

use strict;
use Unicode::Map8 qw(NOCHAR);


print "MAPS_DIR = $Unicode::Map8::MAPS_DIR\n";

my $l1 = Unicode::Map8->new("latin1") || die;
my $no = Unicode::Map8->new("no")     || die;

#dump_map($no);

print "not " unless $no->to8($l1->to16("xyzæøå")) eq "xyz{|}";
print "ok 1\n";

print "not " unless $no->recode8($l1, "xyz{|}") eq "xyzæøå";
print "ok 2\n";


print "not " unless NOCHAR == 0xFFFF;
print "ok 3\n";

my $m = Unicode::Map8->new;

$m->addpair(32, 32);
$m->addpair(32, 160);
$m->addpair(160, 32);
$m->addpair(ord("D"), 0x0394);  # U+0394 = DELTA
dump_map($m);

print "not " unless $m->to16(" ") eq "\0 ";
print "ok 4\n";
print "not " unless $m->to16(chr(160)) eq "\0 ";
print "ok 5\n";
print "not " unless $m->to8("\0 ") eq " ";
print "ok 6\n";
print "not " unless $m->to8("\0" . chr(160)) eq " ";
print "ok 7\n";

print "not " unless $m->to16("D") eq "\x03\x94" &&
                    $m->to8("\x03\x94") eq "D";
print "ok 8\n";
print "not " unless $m->to_char16(ord("D")) == 0x0394 &&
                    $m->to_char8(0x0394) == ord("D") &&
                    $m->to_char16(ord("E")) == NOCHAR &&
                    $m->to_char8(0x0395) == NOCHAR;
print "ok 9\n";

print "---\n";

print "not " unless $m->to16("abc") eq "";  # all unmapped
print "ok 10\n";

$m->default_to16(ord("X"));
$m->default_to8(ord("x"));

print "not " unless $m->default_to16 == ord("X") &&
                    $m->default_to8  == ord("x");
print "ok 11\n";


print "not " unless $m->to16("Dabc") eq "\x03\x94\0X\0X\0X" &&
                    $m->to8("\x03\x94\0a\0b\0c") eq "Dxxx";

print "ok 12\n";

#dump_map($m);

$m->nostrict;
print "not " unless $m->to16("Dabc") eq "\x03\x94\0a\0b\0c" &&
                    $m->to8("\x03\x94\0a\0b\0c") eq "Dabc";
print "ok 13\n";

print "not " if $m->_empty_block(0) && !$m->_empty_block(1);
print "ok 14\n";
undef($m);

# Test parsing of text files
open(T, ">map-$$.txt") or die;
print T <<EOT;
  # foo
#bar

0x01 0x0001 # foo
  0x2 0x3#foo
# This is a stupid mapping file
   # mostly made for testing puposes
           	     0x03  	    0x00033
0x333 0x333
FF FFFF
#EOT
0xAB 0xABCD
EOT
close(T);

$m = Unicode::Map8->new("./map-$$.txt");
unlink("map-$$.txt");

if ($m) {
    print "ok 15\n";
    dump_map($m);
    print "not " unless $m->to_char8(1)    == 1 &&
	                $m->to_char16(1)   == 1 &&
			$m->to_char8(0x33) == 3 &&
	                $m->to_char16(0x3) == 0x33 &&
                        $m->to_char8(0xABCD) == 0xAB &&
                        $m->to_char8(10)   == NOCHAR;
    print "ok 16\n";
    print "not " unless $m->recode8($m, "\0\1\2\3\4") eq "\1\2\3";
    print "ok 17\n";
} else {
    my $test;
    for $test (15 .. 17) {
	print "not ok $test\n";
    }
}

print "not " if Unicode::Map8->new("NOT_FOUND");
print "ok 18\n";


#---------------------------------------------------

sub dump_map
{
    my $m = shift;
    for (my $i = 0; $i < 256; $i++) {
	my $u = $m->to_char16($i);
	next if $u == NOCHAR;
	printf "0x%02X 0x%04X\n", $i, $u;
    }
    for (my $block = 0; $block < 256; $block++) {
	next if $m->_empty_block($block);
	print "# BLOCK $block\n";
	for (my $i = 0; $i < 256; $i++) {
	    my $u = $block*256 + $i;
	    my $c = $m->to_char8($u);
	    next if $c == NOCHAR;
	    printf "0x%04X 0x%02X\n", $u, $c;
	}
    }
}
