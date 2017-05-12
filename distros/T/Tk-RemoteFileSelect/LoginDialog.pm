package Tk::LoginDialog;
my $RCSRevKey = '$Revision: 1.2 $';
$RCSRevKey =~ /Revision: (.*?) /;
$VERSION=0.61;
use vars qw($VERSION @EXPORT_OK);

use Tk qw(Ev);
use Tk::CmdLine;
use strict;
use Carp;
use base qw(Tk::Toplevel);
use Tk::widgets qw(LabEntry DialogBox);

Construct Tk::Widget 'LoginDialog';

my $font="*-helvetica-medium-r-*-*-12-*";

Tk::CmdLine::SetResources ('*font: ' . $font);

sub Populate {
  my ($w, $args) = @_;
  require Tk::Toplevel;
  require Tk::DialogBox;
  require Tk::LabEntry;
  require Tk::Button;
  require Tk::Frame;
  $w->SUPER::Populate($args);

  my $l = $w -> Component( Label => 'toplabel',
			   -text => 'Please enter your user name and password.'
			 ) -> pack( -expand => '1', -fill => 'x', 
				    -ipady => 5, -ipadx => 5);
  $l = $w -> Component( LabEntry => 'userid',
			 -labelVariable => \$w -> {'Configure'}{'-uidlabel'},
			 -textvariable => \$w -> {'Configure'}{'-userid'} )
    -> pack( -anchor => 'w', -expand => '1', -fill => 'x', 
	     -ipady => 5, -ipadx => 5);
  $l = $w -> Component( LabEntry => 'password',
			-labelVariable => \$w -> {'Configure'}{'-pwdlabel'},
			-textvariable => \$w -> {'Configure'}{'-password'},
			-show => '*' )
    -> pack( -anchor => 'w', -expand => '1', -fill => 'x' );
  my $f = $w -> Component( Frame => 'buttons',
			   -container => '0',
			   -relief => 'groove',
			   -borderwidth => '3' );
  my $ok = $f -> Button( -text => 'Login', -width => 6,
			 -default => 'active',
			 -command => sub{ $w->Accept})
    -> pack( -padx => 30, -pady => 5, -side => 'left', -anchor => 'w');
  my $cancel = $f -> Button( -text => 'Cancel', -width => 6,
			     -default => 'normal',
			     -command =>sub{$w->WmDeleteWindow})
    -> pack( -padx => 30, -pady => 5, -side => 'right', -anchor => 'e' );
  $f -> pack( -ipadx => 10, -expand => '1', -fill => 'x' );
  $w->ConfigSpecs(
		-userid   => ['PASSIVE', undef, undef, "" ],
		-password => ['PASSIVE', undef, undef, "" ],
		  -accept => ['PASSIVE', undef, undef, "" ],
		-uidlabel => ['PASSIVE', undef, undef, 'User ID'],
		-pwdlabel => ['PASSIVE', undef, undef, 'Password'],
		);
  $ok -> focus;
  return $w;
}

sub Accept {
  my $w = shift;
  $w -> {Configure}{-accept} = '1';
}

sub Show {
  my( $w, @args) = @_;
  $w -> waitVariable( \$w -> {'Configure'}{'-accept'} );
  $w -> withdraw;
  return 'Login';
}


1;
