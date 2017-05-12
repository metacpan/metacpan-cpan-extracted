package EC::About;
my $RCSRevKey = '$Revision: 1.5 $';
$RCSRevKey =~ /Revision: (.*?) /;
$VERSION=$1;

use Tk qw(Ev);
use strict;
use Carp;
use base qw(Tk::Toplevel);
use Tk::widgets qw(Button Frame Label);
use EC::ECIcon;

Construct Tk::Widget 'About';

sub Populate {
  my ($w, $args) = @_;
  require Tk::Button;
  require Tk::Toplevel;
  require Tk::Label;
  require Tk::Listbox;
  require Tk::Pixmap;
  require Tk::Canvas;
  require EC::ECIcon;
  $w -> SUPER::Populate($args);
  $w->ConfigSpecs(
        -font             => ['CHILDREN',undef,undef,undef],
        -version          => ['PASSIVE',undef,undef,0],
  );
  my $logo = $w -> Pixmap (-data => EC::ECIcon::icondata);
  my $kanvas = $w -> Component ('Canvas' => 'canvas', 
				-width => 64, -height => 64);
  $kanvas -> createImage (1,1, -image => $logo, -anchor => 'nw');
  $kanvas -> grid (-column => 1, -row => 1, -pady => 5);
  my $l = $w -> Component( Label => 'tile',
	   -text => "\nEC Email Client\n Version ".$args->{-version}."\n");
  $l -> grid( -column => 2, -row => 1, -pady => 5, -columnspan => 2);
  my $l2 = $w -> Component( Label => 'copyright',
   -text => "Copyright \xa9 2001-2004,\nRobert Kiesling, " .
   "rkies\@cpan.org.\n" .
   "MS Windows Compatibility by Roland Bauer\n\n" .
   "Please read the file, \"Artistic,\" for license terms.\n");
  $l2 -> grid( -column => 1, -row => 2, -padx => 5, -pady => 5,
	      -columnspan => 3);
  $b = $w->Button( -text => 'Dismiss', -command => sub{$w->WmDeleteWindow},
		   -default => 'active' );
  $b->grid( -column => 1, -row => 3, -padx => 5, -pady => 5,
	   -columnspan => 3);
  $b->focus;

  return $w;
}

1;
