# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $^W = 1 }

use Tk::Enscript;
use strict;
use vars qw($ok);

print "1..50\n";

print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use FindBin;
use Tk;
my $top = new MainWindow;

my $tmpdir = "$FindBin::RealBin/tmp";

$ok = 2;

enscript($top,
	 -font => "Courier7",
	 -media => 'A5',
	 -file => "Enscript.pm",
	 -output => "$tmpdir/test-%02d.ps",
	);
print "not " if !-f "$tmpdir/test-00.ps";
print "ok " . $ok++ . "\n";

foreach my $external ('', 'enscript', 'a2ps') {
    if ($external ne '') {
	if (!Tk::Enscript::_is_in_path($external)) {
	    # skip non-existing external program
	    print "ok " . $ok++ . " # skip: no $external installed\n"
		for (1 .. keys %Tk::Enscript::postscript_to_x11_font);
	    next;
	} elsif ($external eq 'a2ps') {
	    # skip a2ps
	    print "ok " . $ok++ . " # skip: a2ps not supported anymore\n"
		for (1 .. keys %Tk::Enscript::postscript_to_x11_font);
	    next;
	}
    }
    for my $psname (keys %Tk::Enscript::postscript_to_x11_font) {
	my $x11font = Tk::Enscript::postscript_to_x11_font($psname);
	my $font = Tk::Enscript::x11_font_to_tk_font($top, $x11font);
	if (UNIVERSAL::can($font, "as_string")) { # for Tk::X11Font
	    $font = $font->as_string;
	} else {
	    local $^W; $font = "$font";
	}
	if (!defined $font || $font eq '') {
	    print "ok " . $ok++ . " # skip: no X11 font for $psname found\n";
	    next;
	}
	my $psname1 = ucfirst($psname);
	$psname1 =~ s/-([a-z])/-\U$1/g;
	my $filebase = "$tmpdir/test-$psname-$external";
	my $out = ($external eq '' ? "${filebase}-%02d.ps" : $filebase.".ps");
	enscript($top,
		 ($external ne '' ? (-external => $external) : ()),
		 -font => $psname1 . "10",
		 -media => 'A4',
		 -file => "MANIFEST",
		 -output => $out,
		);
	print "not " if (($external eq '' && !-f "${filebase}-00.ps") ||
			 ($external ne '' && !-f "${filebase}.ps"));
	print "ok " . $ok++ . "\n";
    }
}

print STDERR "Look at the tmp directory for the created postscript files.\n";
#MainLoop;

