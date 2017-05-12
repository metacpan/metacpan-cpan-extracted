use strict;
use vars '$loaded';
BEGIN { $^W= 1; $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

use Tk;
use Tk::DynaTabFrame;
use Tk::Text;
use Tk::Photo;

my $mw = MainWindow->new();
$mw->geometry('200x200');
$mw->update;
#
#	create an image
#
my $image = $mw->Photo(-data => projmgmt16_gif(), -format => 'gif');

my $dtf = $mw->DynaTabFrame(
	-font => 'System 8', 
	-tabclose => 1,
	-tabcolor => 'orange',
	-raisecolor => 'green',
	)
	->pack (-side => 'top', -expand => 1, -fill => 'both');
#
#	add a text tab
my $text1 = $dtf->add(
	-caption => 'Tab1',
	-label => 'A textual tab',
)->Text(
	-width => 50, 
	-height => 30, 
	-wrap => 'none',
	-font => 'Courier 10')
	->pack(-fill => 'both', -expand => 1);

$text1->insert('end', "This is the textual tabframe");
#
#	add a image tab
#
my $text2 = $dtf->add(
	-caption => 'Tab2',
	-image => $image,
)->Text(
	-width => 50, 
	-height => 30, 
	-wrap => 'none',
	-font => 'Courier 10')
	->pack(-fill => 'both', -expand => 1);

$text2->insert('end', "This is the image tabframe");

$mw->after(500, \&test_delete);

Tk::MainLoop();

sub test_delete {
	$dtf->delete('Tab1');
	$mw->after(500, \&test_done);
}

sub test_done {
	$loaded = 1;
	print "ok 1\n";
	exit;
}

sub projmgmt16_gif {
	# FILENAME: C:/Perl/TeraForge/TeraForge-0.20/src/icons/projmgmt16.gif
	# THIS FUNCTION RETURNS A BASE64 ENCODED
	# REPRESENTATION OF THE ABOVE FILE.
	# SUITABLE FOR USE BY THE -data PROPERTY.
	# OF A Perl/Tk PHOTO.
	my $binary_data = <<EOD;
R0lGODlhEgASAPcAAOecUgAAAMbGxv8A/wD//4QAhACEhISEhP///wD/AACEAISEAAAA/wAAhP//
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACwAAAAAEgASAAAIrwAFCBSw
IECAAgYBDFwocIEBAwcHDCgAIABDgQcaEIB4EOGBAAdCHhh44OFGgxYRWFyAAMHCAwpQDlSZsWVI
gQgWAABwwKaCBiMF5By4QIDBAkENIjhQMGhRlwIbBFgqgGnBhj0RIBX6sSdTgwNBMs3YwGjDAFeJ
tmwpVGhOBWmFTnVAly6AugviGkVQty/dvBbD8vWLV+9cwn/jqhSA+C/ahQUYIy5YdCHKy5cZBgQA
Ow==
EOD
	return($binary_data);
	} # END projmgmt16_gif...
