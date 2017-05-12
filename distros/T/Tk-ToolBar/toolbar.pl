# Tk::ToolBar - a draggable ToolBar widget

#!perl -w

use strict;
use Tk;
use Tk::ToolBar;
#use Tk::LabOptionmenu;

my $mw = MainWindow->new;
my $tb = $mw->ToolBar;

my $cv = $mw->Canvas(qw/-bg black/)->pack(qw/-fill both -expand 1/);
$cv->createPolygon(0, 0, 50, 100, 100, 0, 0, 50, 100, 50, 0, 0,
		   -fill => 'white');

$mw->Button(-text    => 'See built-in images',
	    -command => \&seeBuiltIns,
	   )->pack;

for my $img (qw/filenew22 fileopen22 filesave22/) {
  $tb->ToolButton(-image => $img,
		  -tip => $img);
}

$tb->separator;

for my $img (qw/editcopy22 editcut22 editpaste22 editdelete22/) {
  $tb->ToolButton(-image => $img,
		  -tip => $img);
}

$tb->separator;

$tb->ToolButton(-image   => 'actexit22',
		-tip     => 'Quit',
		-command => [$mw, 'destroy']);

MainLoop;

sub seeBuiltIns {
  #my @files  = qw/tkIcons tkIcons.crystal tkIcons.klassic/;
  my @files  = qw/tkIcons/;

  my $t = $mw->Toplevel;
  $t->title("Tk::ToolBar's built-in images");

  my $g = $t->Frame->pack(qw/-side top -fill x/);
  $t->Label(-text => 'Click on icon to see its name')->pack(qw/-side top -expand 1/);

  my %frame;
  $frame{$_} = $t->Frame for @files;

  my ($sel, $cur);

  $g->Button(-text    => 'Close Window',
	     -command => [$t => 'destroy'],
	    )->pack(qw/-side left -expand 1/);

  $g->Label(-text => 'Icon Style')->pack(qw/-side left/);
  $g->Optionmenu(
		 #-label    => 'Icon Style',
		 -options  => \@files,
		 -variable => \$sel,
		 -command  => sub {
		   $frame{$cur}->packForget if $cur;
		   $frame{$sel}->pack(qw/-side bottom/);
		   $cur = $sel;
		 })->pack(qw/-side left/);

  for my $ff (@files) {
    my $frame = $frame{$ff};
    my $file  = Tk->findINC("ToolBar/$ff");
    die "ERROR: Can't find tkIcons!\n" unless defined $file;

    open my $fh, $file or die $!;

    my %icons;

    while (<$fh>) {
      chomp;
      my ($n, $d) = (split /:/)[0, 4];

      $icons{$n} = $mw->Photo("$ff.$n", -data => $d);
    }

    close $fh;

    my $selected = 'None';
    $frame->Label(-textvariable => \$selected)->pack(qw/-side top/);

    my $f = $frame->Frame->pack(qw/-fill both -expand 1/);

    my $r = my $c = 0;
    my %labels;

    for my $n (sort keys %icons) {
      my $l = $f->Label(
			-image         => "$ff.$n",
		       )->grid(-column => $c,
			       -row    => $r,
			      );

      $labels{$n} = $l;

      $l->bind('<1>' => sub {
		 if ($selected ne 'None') {
		   $labels{$selected}->configure(-borderwidth => 0, -bg => Tk::ACTIVE_BG);#defaultthing);
		 }

		 $selected = $n;
		 $l->configure(-borderwidth => 2, -bg => 'white');
	       });

      $c++;
      if ($c == 20) {
	$r++;
	$c = 0;
      }
    }
  }
}
