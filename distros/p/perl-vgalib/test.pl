# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use vga;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

@bitmap=([0,0,0,1,1,1,1,0,0,0],
	 [0,1,1,1,1,1,1,1,1,0],
	 [0,1,1,0,1,1,0,1,1,0],
	 [1,1,1,1,1,1,1,1,1,1],
	 [1,1,1,1,1,1,1,1,1,1],
	 [0,1,0,1,1,1,1,0,1,0],
	 [0,1,1,0,1,1,0,1,1,0],
	 [0,0,1,1,0,0,1,1,0,0],
	 [0,0,0,1,1,1,1,0,0,0],
	 [0,0,0,0,0,0,0,0,0,0]);

sub rainbow_screen {
	for $x (0..319) {
		for $y(0..199) {
			&vga::setcolor($x+$y);
			&vga::drawpixel($x,$y);
		}
	}
}

sub draw_smiley {
	($xpos,$ypos)=@_;
	for $x (0..9) {
		for $y (0..9) {
			&vga::setcolor($bitmap[$y][$x]);
			&vga::drawpixel($xpos+$x,$ypos+$y);
		}
	}
}

&vga::setmode(G320x200x256);
&vga::clear();

for $x (1..180) {
&vga::waitretrace;
&vga::clear();
&draw_smiley($x,$x);
}
print "press a key.";
&vga::getch();
&rainbow_screen;
$key=&vga::getch();
&vga::setmode(__GLASTMODE);
print "You pressed ",chr($key)," (ASCII $key) - all seems well.\n";
