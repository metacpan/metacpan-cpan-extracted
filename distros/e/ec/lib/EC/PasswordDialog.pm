package EC::PasswordDialog;
my $RCSRevKey = '$Revision: 1.2 $';
$RCSRevKey =~ /Revision: (.*?) /;
$VERSION=$1;
use vars qw($VERSION @EXPORT_OK);
@EXPORT_OK = qw(glob_to_re);

=head1 NAME 

   PasswordDialog - Password entry.

=head1 SYNOPSIS

  $d = $mw -> PasswordDialog (-username => 'login' );
  $d -> WaitForInput

  The -font option defaults to *-helvetica-medium-r-*-*-12-*.
  The -username option supplies the default text for the user
  name entry box.

=head1 DESCRIPTION

  A widget for the ec email program - refer to the ec documentation.

=cut

use Tk qw(Ev);
use strict;
use Carp;
use base qw(Tk::Toplevel);
use Tk::widgets qw(LabEntry Button Frame);

Construct Tk::Widget 'PasswordDialog';

sub Password {
  my ($w) = @_;
  $w -> {Configure}{'-password'} =
    $w -> Subwidget( 'passwordentry' ) -> get;
}

sub Populate {
  my ($w,$args) = @_;
  require Tk::Button;
  require Tk::Toplevel;
  require Tk::Label;
  require Tk::Entry;
  $w->SUPER::Populate($args);

  $w -> configure( -title => 'Enter Password' );

  $w->ConfigSpecs( -font =>    ['CHILDREN',undef,undef,
	                         '*-helvetica-medium-r-*-*-12-*'],
		   -username => ['PASSIVE',undef,undef,''],
		   -password => ['PASSIVE',undef,undef,undef] );

  my $l1 = $w -> Component ( Label => 'usernamelabel',
			     -text => 'User Name:', );
  $l1 -> grid ( -column => 1, -row => 1, -padx => 5, -pady => 5,
		-sticky => 'w', -columnspan => 2 );
  my $e1 = $w -> Component (Entry => 'usernameentry',
			    -width => 20,
		            -textvariable => \$w->{'Configure'}{'-username'});
  $e1 -> grid ( -column => 3, -row => 1, -padx => 5, -pady => 5,
		-sticky => 'w', -columnspan => 3 );
  my $l2 = $w -> Component (Label => 'passwordlabel',
			    -text => 'Password:', );
  $l2 -> grid ( -column => 1, -row => 2, -padx => 5, -pady => 5,
		-sticky => 'w', -columnspan => 2 );
  my $e2 = $w -> Component (Entry => 'passwordentry',
			    -width => 20,
			   -show => '*' );
  $e2 -> bind( '<Return>', sub {$w -> Password} );
  $e2 -> grid ( -column => 3, -row => 2, -padx => 5, -pady => 5,
		-sticky => 'w', -columnspan => 3 );
  my $b1 = $w -> Component (Button => 'okbutton',
			    -text => 'Ok',
			    -command => sub {$w -> Password},
			    -default => 'active' );
  $b1->grid( -column => 2, -row => 3, -padx => 5, -pady => 5,
	    -sticky => 'new' );
  $b1->focus;
  my $b2 = $w -> Component (Button => 'cancelbutton',
			    -text => 'Cancel',
			    -command => sub{$w -> WmDeleteWindow},
			    -default => 'normal' );
  $b2->grid( -column => 4, -row => 3, -padx => 5, -pady => 5,
	    -sticky => 'new' );

  return $w;
}

sub WaitForInput {
  my ($w, @args) = @_;
 $w -> waitVariable( \$w->{'Configure'}{'-password'} );
 $w -> withdraw;
 return $w -> {'Configure'}{'-password'};
}

1;
