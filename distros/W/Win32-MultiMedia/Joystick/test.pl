# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Win32::MultiMedia::Joystick;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $num = Win32::MultiMedia::Joystick::GetNumDevs();
print "\nYour system can support $num joystick(s).\n\n";

for my $i (1..$num)
{
	my $joy = Win32::MultiMedia::Joystick->new($i-1);
	if ($joy)
	{
		print "Joystick $i found: ", $joy->Name,"\n";

		print "\tJoystick $i capabilities:\n";
		print "\tX range: ",$joy->Xmin,"..",$joy->Xmax,"\n";
		print "\tY range: ",$joy->Ymin,"..",$joy->Ymax,"\n";
		if ($joy->hasZ)	{print "\tZ range: ",$joy->Zmin,"..",$joy->Zmax,"\n"}
		else {print "\tHas no Z\n"}
		if ($joy->hasR)	{print "\tR range: ",$joy->Rmin,"..",$joy->Rmax,"\n"}
		else {print "\tHas no R\n"}
		if ($joy->hasU)	{print "\tU range: ",$joy->Umin,"..",$joy->Umax,"\n"}
		else {print "\tHas no U\n"}
		if ($joy->hasV)	{print "\tV range: ",$joy->Vmin,"..",$joy->Vmax,"\n"}
		else {print "\tHas no V\n"}
		if ($joy->hasPOV)	{print "\tPov is ", $joy->hasPOVCTS?"continuous":"descrete", "\n"}
		else {print "\tHas no POV\n"}

		print "\n\tJoystick has ",$joy->NumButtons," buttons\n\n";
	}
	else
	{
		print "No $i Joystick found.\n"; 
	}
}

