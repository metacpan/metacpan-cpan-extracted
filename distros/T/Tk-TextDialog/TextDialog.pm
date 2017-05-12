package TextDialog;
$VERSION=0.01;
use vars qw($VERSION @EXPORT_OK);

=head1 NAME

Tk::TextDialog - Dialog widget with text entry.

=head1 SYNOPSIS

  use Tk;
  use Tk::TextDialog;

  $d = $w -> TextDialog ( -font => [-family=>'helvetica',-size=>12, -weight=>'normal'],
			   -title => 'Text Entry',
			   -textlabel => 'Please enter your text:');
  $d -> WaitForInput;
  $d -> destroy;

=head1 DESCRIPTION

  The -font option defaults to helvetica 12

  The -textlabel option prints the text of its argument in label above
  the text entry box.

  After WaitForInput is called, clicking on the 'Accept' button closes the dialog
  and returns the text in the entry box.

  The WaitForInput method does not destroy the dialog window.  Instead 
  WaitForInput unmaps the dialog box from the display.  To de-allocate 
  the widget, you must explicitly call $w -> destroy or $w -> DESTROY.

  Refer to the Tk::options man page for a description of options 
  common to all Perl/Tk widgets.

  Example:

    use Tk;
    use Tk::TextDialog;

    my $w = new MainWindow;

    my $b = $w -> Button (-text => 'Dialog',
                          -command => sub{&show_dialog($w)}) -> pack;

    sub show_dialog {
        my ($w) = @_;
        my $e;
        if (not defined $e) {
	    $e = $w -> TextDialog (-title => 'Enter Text', -height=>5, -width=>20); # Height and width of the text box
        $e -> configure (-textlabel => 'Please enter your text:');
        }
        my $resp = $e -> WaitForInput;
	print "$resp\n";
	$e -> configure (-textlabel => '');
	my $resp = $e -> WaitForInput;
	print "$resp\n";
        return $resp;
    }

    MainLoop;

=head1 VERSION

  $Revision: 0.0.1 $

  Licensed for free distribution under the terms of the 
  Perl Artistic License.

  Written by Mark Daglish ,mark-daglish@blueyonder.co.uk>, but heavily copied from the EntryDialog module written 
  by Robert Allan Kiesling <rkiesling@earthlink.net> and Dave Scheck <cds033@email.mot.com>.

=cut

use Tk;
use strict;
use Carp;
use base qw(Tk::Toplevel);
use Tk::widgets qw(Text Button);

Construct Tk::Widget 'TextDialog';

sub Accept {$_[0]->{Configure}{-accept} += 1}

sub Cancel {
	$_[0]->delete('0.1','end');
    $_[0] -> {Configure}{-accept} += 1;
}

sub textlabel {
    my $w = $_[0];
    my $text = $_[1];
    if (defined $text and length ($text)) {
		my $l1 = $w->Subwidget('Frame')->Component(Label=>'textlabel', -textvariable=>\$w->{Configure}{-textlabel}, -font=>$w->{Configure}{-font});
		$l1->pack( -padx=>5, -pady=>5, -side=>'top');
		$w->Advertise('textlabel' => $l1);

		$w->Subwidget('text')->pack( -side=>'top', -expand=>1, -fill=>'both');
		$w->Subwidget('acceptbutton')->pack( -padx=>5, -pady=>5, -side=>'left');
		$w->Subwidget('cancelbutton')->pack( -padx=>5, -pady=>5, -side=>'right');
	} else {
		$w->Subwidget('textlabel')->destroy if defined $w->Subwidget('textlabel');
    }
}

sub height {
	my ($cw,$h) = @_;
	$cw->Subwidget('text')->configure(-height=>$h) if (defined($h));
}

sub width {
	my ($cw,$w) = @_;
	$cw->Subwidget('text')->configure(-width=>$w) if (defined($w));
}

sub foreground {
    my ($cw,$fg)=@_;
    $cw->Subwidget('text')->configure(-foreground=>$fg) if (defined($fg));
}

sub background {
    my ($cw,$bg) = @_;
    $cw->Subwidget('text')->configure(-background=>$bg) if (defined($bg));
}

sub Populate {
	my ($w,$args) = @_;
	require Tk::Button;
	require Tk::Toplevel;
	require Tk::Label;
	require Tk::Text;
	$w->SUPER::Populate($args);

	$w->ConfigSpecs(	-font => ['ADVERTISED','font','Font',[-family=>'helvetica', -size=>12, -weight=>'normal']],
		   		-textlabel => ['METHOD',undef,undef,''],
		   		-accept => ['PASSIVE',undef,undef,0],
		   		-height => ['METHOD',undef,undef,5],
		   		-width => ['METHOD',undef,undef,20],
                      -foreground => ['METHOD',undef,undef,'black'],
                      -background => ['METHOD',undef,undef,'white'] );

	$w->withdraw;
    my $f = $w->Component(Frame =>'Frame');
    $f->pack(-side=>'top');
	$w->configure(-textlabel=>$args->{-textlabel}) if (defined $args->{-textlabel} and length ($args->{-textlabel}));
	$args->{-height}=5 unless defined($args->{-height});
	$args->{-width}=20 unless defined($args->{-width});
    $args->{-foreground}='black' unless defined($args->{-foreground});
    $args->{-background}='white' unless defined($args->{-background});
	my $e1 = $w->Component(Text => 'text', -delegate=>['get', 'delete'], -height=>$args->{-height}, -width=>$args->{-width}, -foreground=>$args->{-foreground}, -background=>$args->{-background});
	$e1->pack(-side=>'top', -fill=>'both', -expand=>1);
	$w -> Advertise ('text' => $e1);
	my $b1 = $w -> Component (Button => 'acceptbutton',
				-text => 'Accept',
				-default => 'active' );
	$b1->pack( -padx=>5, -pady=>5, -side=>'left');
	$b1->bind('<Button-1>', sub {$w -> Accept});
	$b1->focus;
	my $b2 = $w->Component(Button => 'cancelbutton',
			    -text => 'Cancel',
			    -command => sub{$w -> Cancel},
			    -default => 'normal' );
	$b2->pack( -padx=>5, -pady=>5, -side=>'right');
	return $w;
}

sub WaitForInput {
  my ($w, @args) = @_;
  $w -> Popup (@args);
  $w -> waitVariable(\$w->{Configure}{-accept});
  $w -> withdraw;
  return $w->get('0.1','end');
}

1;
