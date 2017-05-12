###########################################################
# This test script should load a Windows Metafile and 
# Show it in a wxPerl frame
#
use strict;
use warnings;

use Wx;
use Wx::Metafile;
use Test::Simple;
BEGIN { print "1..1\n" }

my $wxobj = MyApp->new();
$wxobj->MainLoop;

#############################################################
# A very basic App class
package MyApp;
use base qw(Wx::App);

sub OnInit
{
	my $self = shift;
	my $frame = MyFrame->new(undef, -1, 'test');
	$frame->Show(1);
}

#############################################################
# A simple Frame class, showing the metafile
package MyFrame;
use base qw(Wx::Frame);

sub new
{
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	my ($bmp, $tmpdc);

	# We want to load test.emf
	my $mf = Wx::Metafile->new('./test.emf');
	die "Can't open $mf\n" if not defined $mf;
	# We create an empty bitmap
    $bmp = Wx::Bitmap->new(100,100);
    # And a temporary DC
    $tmpdc = Wx::MemoryDC->new();
    # Everything we do in the DC changes the bitmap
    $tmpdc->SelectObject($bmp);

	# if it loads OK
	if ($mf->Ok)
	{
		# We 'play' it inside the DC
		$mf->Play($tmpdc, Wx::Rect->new(0,0,100,100));
	}
	my $bb = Wx::BitmapButton->new($self, -1, $bmp);
	print "ok 1\n";
	return $self;
}