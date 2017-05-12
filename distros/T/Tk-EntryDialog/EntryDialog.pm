package EntryDialog;
$VERSION=0.10;
use vars qw($VERSION @EXPORT_OK);

=head1 NAME

Tk::EntryDialog - Dialog widget with text entry.

=head1 SYNOPSIS

  use Tk;
  use Tk::EntryDialog;

  $d = $w -> EntryDialog ( -font => '*-helvetica-medium-r-*-*-12-*',
			   -title => 'Text Entry',
			   -textlabel => 'Please enter your text:',
                           -defaultentry => 'Text in entry widget' );
  $d -> WaitForInput;

=head1 DESCRIPTION

  The -font option defaults to *-helvetica-medium-r-*-*-12-*.
  The -defaultentry option supplies the default text in the Entry
  widget.

  The -textlabel option prints the text of its argument in label above
  the text entry box.

  After WaitForEntry is called, clicking on the 'Accept' button or
  pressing Enter in the text entry widget, closes the dialog and returns
  the text in the entry box.

  The WaitForEntry method does not destroy the dialog window.  Instead 
  WaitForEntry unmaps the dialog box from the display.  To de-allocate 
  the widget, you must explicitly call $w -> destroy or $w -> DESTROY.

  Refer to the Tk::options man page for a description of options 
  common to all Perl/Tk widgets.

  Example:

    use Tk;
    use Tk::EntryDialog;

    my $w = new MainWindow;

    my $b = $w -> Button (-text => 'Dialog',
                          -command => sub{&show_dialog($w)}) -> pack;

    sub show_dialog {
        my ($w) = @_;
        my $e;
        if (not defined $e) {
	    $e = $w -> EntryDialog (-title => 'Enter Text');
            $e -> configure (-defaultentry => 'Default text');
	    $e -> configure (-textlabel => 'Please enter your text:');
        }
        my $resp = $e -> WaitForInput;
	print "$resp\n";
	$e -> configure (-textlabel => '');
	$e -> configure (-defaultentry => 'New entry without label.');
        my $resp = $e -> WaitForInput;
	print "$resp\n";
        return $resp;
    }

    MainLoop;

=head1 VERSION

  $Revision: 0.10 $

  Licensed for free distribution under the terms of the 
  Perl Artistic License.

  Written by Robert Allan Kiesling <rkiesling@earthlink.net>.

  Dave Scheck <cds033@email.mot.com> provided the input for the 
  -textlabel option.

=cut

use Tk qw(Ev);
use strict;
use Carp;
use base qw(Tk::Toplevel);
use Tk::widgets qw(Entry Button);

Construct Tk::Widget 'EntryDialog';

sub Accept {$_[0]->{Configure}{-accept} += 1}

sub Cancel {
    $_[0] -> {Configure}{-defaultentry} = '';
    $_[0] -> {Configure}{-accept} += 1;
}

sub textlabel {
    my $w = $_[0];
    my $text = $_[1];
    if (defined $text and length ($text)) {
	my $l1 = $w->Component (Label => 'textlabel', 
			-textvariable => \$w->{Configure}{-textlabel},
			-font => $w -> {Configure}{-font});
	$l1->grid( -column => 1, -row => 1, -padx => 5, -pady => 5,
		   -sticky => 'ew', -columnspan => 5 );
	$w->Advertise('textlabel' => $l1);

	$w -> Subwidget ('entry')  -> 
	    grid ( -column => 1, -row => 2, -padx => 5, -pady => 5,
		-sticky => 'ew', -columnspan => 5 );
	$w -> Subwidget ('acceptbutton') -> 
	    grid( -column => 2, -row => 3, -padx => 5, -pady => 5, 
		  -sticky => 'new' );
	$w -> Subwidget ('cancelbutton') -> 
	    grid ( -column => 4, -row => 3, -padx => 5, -pady => 5, 
		   -sticky => 'new' );
    } else {
	$w -> Subwidget ('textlabel') -> destroy if 
	    defined $w -> Subwidget ('textlabel');
    }
}

sub Populate {
  my ($w,$args) = @_;
  require Tk::Button;
  require Tk::Toplevel;
  require Tk::Label;
  require Tk::Entry;
  $w->SUPER::Populate($args);

  $w->ConfigSpecs( -font =>    ['CHILDREN',undef,undef,
	                         '*-helvetica-medium-r-*-*-12-*'],
		   -defaultentry => ['PASSIVE',undef,undef,''],
		   -textlabel => ['METHOD',undef,undef,''],
		   -accept => ['PASSIVE',undef,undef,0] );

  my $row = 1;
  $w -> withdraw;
  
  $row++ if (defined $args->{-textlabel} and length ($args->{-textlabel}));

  my $e1 = $w -> Component (Entry => 'entry', 
		            -textvariable => \$w->{Configure}{-defaultentry});
  $e1 -> grid ( -column => 1, -row => $row++, -padx => 5, -pady => 5,
		-sticky => 'ew', -columnspan => 5 );
  $w -> Advertise ('entry' => $e1);
  $e1 -> bind ('<Return>', sub {$w -> Accept});
  my $b1 = $w -> Component (Button => 'acceptbutton',
			    -text => 'Accept',
			    -default => 'active' );
  $b1->grid( -column => 2, -row => $row, -padx => 5, -pady => 5, -sticky => 'new' );
  $b1 -> bind ('<Button-1>', sub {$w -> Accept});
  $b1->focus;
  my $b2 = $w -> Component (Button => 'cancelbutton',
			    -text => 'Cancel',
			    -command => sub{$w -> Cancel},
			    -default => 'normal' );
  $b2->grid( -column => 4, -row => $row, -padx => 5, -pady => 5, -sticky => 'new' );

  $w -> bind ('<Escape>', sub {$w -> withdraw});

  return $w;
}

sub WaitForInput {
  my ($w, @args) = @_;
  $w -> Popup (@args);
  $w -> waitVariable(\$w->{Configure}{-accept});
  $w -> withdraw;
  return $w -> {Configure}{-defaultentry};
}

1;
