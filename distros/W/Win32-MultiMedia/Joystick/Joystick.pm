package Win32::MultiMedia::Joystick;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

%EXPORT_TAGS = ( 
	direct => [ qw(
		GetNumDevs  GetInfo  GetDevCaps GetThreshold ReleaseCapture 
		SetCapture SetThreshold GetError
	) ] ,
	error =>[ qw (
		JOYERR_BASE JOYERR_NOERROR JOYERR_PARMS JOYERR_NOCANDO JOYERR_UNPLUGGED
	)],
	button =>[ qw(
		JOY_BUTTON1 JOY_BUTTON2 JOY_BUTTON3 JOY_BUTTON4 JOY_BUTTON1CHG JOY_BUTTON2CHG 
		JOY_BUTTON3CHG JOY_BUTTON4CHG JOY_BUTTON5 JOY_BUTTON6 JOY_BUTTON7 JOY_BUTTON8 
		JOY_BUTTON9 JOY_BUTTON10 JOY_BUTTON11 JOY_BUTTON12 JOY_BUTTON13 JOY_BUTTON14 
		JOY_BUTTON15 JOY_BUTTON16 JOY_BUTTON17 JOY_BUTTON18 JOY_BUTTON19 JOY_BUTTON20 
		JOY_BUTTON21 JOY_BUTTON22 JOY_BUTTON23 JOY_BUTTON24 JOY_BUTTON25 JOY_BUTTON26 
		JOY_BUTTON27 JOY_BUTTON28 JOY_BUTTON29 JOY_BUTTON30 JOY_BUTTON31 JOY_BUTTON32 
	)],
	pov =>[qw(
		JOY_POVFORWARD JOY_POVRIGHT JOY_POVBACKWARD JOY_POVLEFT 
	)],
	messages=>[qw(
		MM_PC_JOYSTICK MM_JOY1MOVE MM_JOY2MOVE MM_JOY1ZMOVE MM_JOY2ZMOVE MM_JOY1BUTTONDOWN 
		MM_JOY2BUTTONDOWN MM_JOY1BUTTONUP MM_JOY2BUTTONUP 
	)]
);

Exporter::export_ok_tags( qw( direct error button pov messages ));


@EXPORT = @{ $EXPORT_TAGS{'error'} };
$VERSION = '0.01';

bootstrap Win32::MultiMedia::Joystick $VERSION;


#constants
use constant JOYERR_BASE	 => 160;
use constant JOYERR_NOERROR		=>  0;               #   /* no error */
use constant JOYERR_PARMS    =>      (JOYERR_BASE+5);  #    /* bad parameters */
use constant JOYERR_NOCANDO   =>     (JOYERR_BASE+6);   #    /* request not completed */
use constant JOYERR_UNPLUGGED  =>     (JOYERR_BASE+7); #     /* joystick is unplugged */

use constant JOYSTICKID1	 => 0;
use constant JOYSTICKID2	 => 1;
use constant JOY1	 => JOYSTICKID1;
use constant JOY2	 => JOYSTICKID2;

use constant MAX_JOYSTICKOEMVXDNAME	 => 260; 	# max oem vxd name length (including NULL) ;
use constant MM_PC_JOYSTICK	 => 12;   	# Joystick adapter ;

#messages for captured joysticks
use constant MM_JOY1MOVE	 => 0x3A0;           	# joystick ;
use constant MM_JOY2MOVE	 => 0x3A1;
use constant MM_JOY1ZMOVE	 => 0x3A2;
use constant MM_JOY2ZMOVE	 => 0x3A3;
use constant MM_JOY1BUTTONDOWN	 => 0x3B5;
use constant MM_JOY2BUTTONDOWN	 => 0x3B6;
use constant MM_JOY1BUTTONUP	 => 0x3B7;
use constant MM_JOY2BUTTONUP	 => 0x3B8;

use constant JOY_BUTTON1CHG	 => 0x0100;
use constant JOY_BUTTON2CHG	 => 0x0200;
use constant JOY_BUTTON3CHG	 => 0x0400;
use constant JOY_BUTTON4CHG	 => 0x0800;

use constant JOY_BUTTON1	 => 0x0001;
use constant JOY_BUTTON2	 => 0x0002;
use constant JOY_BUTTON3	 => 0x0004;
use constant JOY_BUTTON4	 => 0x0008;
use constant JOY_BUTTON5	 => 0x00000010;
use constant JOY_BUTTON6	 => 0x00000020;
use constant JOY_BUTTON7	 => 0x00000040;
use constant JOY_BUTTON8	 => 0x00000080;
use constant JOY_BUTTON9	 => 0x00000100;
use constant JOY_BUTTON10	 => 0x00000200;
use constant JOY_BUTTON11	 => 0x00000400;
use constant JOY_BUTTON12	 => 0x00000800;
use constant JOY_BUTTON13	 => 0x00001000;
use constant JOY_BUTTON14	 => 0x00002000;
use constant JOY_BUTTON15	 => 0x00004000;
use constant JOY_BUTTON16	 => 0x00008000;
use constant JOY_BUTTON17	 => 0x00010000;
use constant JOY_BUTTON18	 => 0x00020000;
use constant JOY_BUTTON19	 => 0x00040000;
use constant JOY_BUTTON20	 => 0x00080000;
use constant JOY_BUTTON21	 => 0x00100000;
use constant JOY_BUTTON22	 => 0x00200000;
use constant JOY_BUTTON23	 => 0x00400000;
use constant JOY_BUTTON24	 => 0x00800000;
use constant JOY_BUTTON25	 => 0x01000000;
use constant JOY_BUTTON26	 => 0x02000000;
use constant JOY_BUTTON27	 => 0x04000000;
use constant JOY_BUTTON28	 => 0x08000000;
use constant JOY_BUTTON29	 => 0x10000000;
use constant JOY_BUTTON30	 => 0x20000000;
use constant JOY_BUTTON31	 => 0x40000000;
use constant JOY_BUTTON32	 => 0x80000000;

use constant JOY_POVFORWARD	 => 0;
use constant JOY_POVRIGHT	 => 9000;
use constant JOY_POVBACKWARD	 => 18000;
use constant JOY_POVLEFT	 => 27000;


sub new
{
	my ($this, $devID,$raw)=@_;
	$devID||=0;
	$raw||=0;
	my $caps = GetDevCaps($devID);
	my $info = GetInfo($devID,$raw);
	return undef if !($caps and $info);
	my $self = 
	{
		ID => $devID,
		RAW => $raw,
		CAPS => $caps,
		INFO => $info
	};
	bless $self, ref($this) || $this;
}

sub id {$_[0]->{ID}}

sub isUsingRaw {$_[0]->{RAW}}

sub setRaw {$_[0]->{RAW}=$_[1]}

sub error 
{
	my $self = shift;
	return GetError() if !ref($self);  #called as a function

	my $error= $self->{ERROR} ;
	if (wantarray)
	{
		return ($error, "bad parameter") if $error==JOYERR_PARMS;
		return ($error, "request not completed") if $error==JOYERR_NOCANDO;
		return ($error, "joystick unplugged") if $error==JOYERR_UNPLUGGED;
	}
	return $error;		
}

sub update
{
	my $self = shift;
	my $info = GetInfo($self->{ID},$self->{RAW});
	$self->{INFO} = $info if defined $info;
	$self->{ERROR} = GetError();
	return defined $info;
}

sub threshold
{
	my $self=shift();
	my $ret =0;
	if (@_)
	{
		$ret=SetThreshold($self->{ID},shift());
	}
	else
	{
		$ret=GetThreshold($self->{ID});
	}
	$self->{ERROR} = GetError();
	return $ret;
}

sub setCapture
{
	my $self=shift();
	SetCapture(shift,$self->{ID},shift,shift);
	$self->{ERROR} = GetError();
}

sub releaseCapture
{
	my $self=shift();
	ReleaseCapture($self->{ID});
	$self->{ERROR} = GetError();
}


#### Joystick caps
sub ProductID 	{$_[0]->{CAPS}{ProductID}}
sub ManufacturerID 	{$_[0]->{CAPS}{ManufacturerID}}
sub Name 	{$_[0]->{CAPS}{Name}}

sub hasPOV 	{$_[0]->{CAPS}{hasPOV}}
sub hasPOV4DIR 	{$_[0]->{CAPS}{hasPOV4DIR}}
sub hasPOVCTS 	{$_[0]->{CAPS}{hasPOVCTS}}

sub hasZ 	{$_[0]->{CAPS}{hasZ}}
sub hasR 	{$_[0]->{CAPS}{hasR}}
sub hasU 	{$_[0]->{CAPS}{hasU}}
sub hasV 	{$_[0]->{CAPS}{hasV}}

sub MaxAxes 	{$_[0]->{CAPS}{MaxAxes}}
sub NumAxes 	{$_[0]->{CAPS}{NumAxes}}
sub MaxButtons 	{$_[0]->{CAPS}{MaxButtons}}
sub NumButtons 	{$_[0]->{CAPS}{NumButtons}}
sub PeriodMax 	{$_[0]->{CAPS}{PeriodMax}}
sub PeriodMin 	{$_[0]->{CAPS}{PeriodMin}}

sub Xmax 	{$_[0]->{CAPS}{Xmax}}
sub Xmin 	{$_[0]->{CAPS}{Xmin}}
sub Ymax 	{$_[0]->{CAPS}{Ymax}}
sub Ymin 	{$_[0]->{CAPS}{Ymin}}
sub Zmax 	{$_[0]->{CAPS}{Zmax}}
sub Zmin 	{$_[0]->{CAPS}{Zmin}}

sub Rmax 	{$_[0]->{CAPS}{Rmax}}
sub Rmin 	{$_[0]->{CAPS}{Rmin}}
sub Umax 	{$_[0]->{CAPS}{Umax}}
sub Umin 	{$_[0]->{CAPS}{Umin}}
sub Vmax 	{$_[0]->{CAPS}{Vmax}}
sub Vmin 	{$_[0]->{CAPS}{Vmin}}

#####Joystick info
sub X 	{$_[0]->{INFO}{X}}
sub Y 	{$_[0]->{INFO}{Y}}
sub Z 	{$_[0]->{INFO}{Z}}

sub R 	{$_[0]->{INFO}{R}}
sub U 	{$_[0]->{INFO}{U}}
sub V 	{$_[0]->{INFO}{V}}

sub ButtonNumber 	{$_[0]->{INFO}{ButtonNumber}}
sub B1 	{$_[0]->{INFO}{B1}}
sub B2 	{$_[0]->{INFO}{B2}}
sub B3 	{$_[0]->{INFO}{B3}}
sub B4 	{$_[0]->{INFO}{B4}}
sub B5 	{$_[0]->{INFO}{B5}}
sub B6 	{$_[0]->{INFO}{B6}}
sub B7 	{$_[0]->{INFO}{B7}}
sub B8 	{$_[0]->{INFO}{B8}}
sub B9 	{$_[0]->{INFO}{B9}}
sub B10 	{$_[0]->{INFO}{B10}}
sub B11 	{$_[0]->{INFO}{B11}}
sub B12 	{$_[0]->{INFO}{B12}}
sub B13 	{$_[0]->{INFO}{B13}}
sub B14 	{$_[0]->{INFO}{B14}}
sub B15 	{$_[0]->{INFO}{B15}}
sub B16 	{$_[0]->{INFO}{B16}}
sub B17 	{$_[0]->{INFO}{B17}}
sub B18 	{$_[0]->{INFO}{B18}}
sub B19 	{$_[0]->{INFO}{B19}}
sub B20 	{$_[0]->{INFO}{B20}}
sub B21 	{$_[0]->{INFO}{B21}}
sub B22 	{$_[0]->{INFO}{B22}}
sub B23 	{$_[0]->{INFO}{B23}}
sub B24 	{$_[0]->{INFO}{B24}}
sub B25 	{$_[0]->{INFO}{B25}}
sub B26 	{$_[0]->{INFO}{B26}}
sub B27 	{$_[0]->{INFO}{B27}}
sub B28 	{$_[0]->{INFO}{B28}}
sub B29 	{$_[0]->{INFO}{B29}}
sub B30 	{$_[0]->{INFO}{B30}}
sub B31 	{$_[0]->{INFO}{B31}}
sub B32 	{$_[0]->{INFO}{B32}}

sub Buttons 	{$_[0]->{INFO}{Buttons}}
sub POV 	{$_[0]->{INFO}{POV}}

sub POVCENTERED 	{$_[0]->{INFO}{POVCENTERED}}
sub POVFORWARD 	{$_[0]->{INFO}{POVFORWARD}}
sub POVRIGHT 	{$_[0]->{INFO}{POVRIGHT}}
sub POVBACKWARD 	{$_[0]->{INFO}{POVBACKWARD}}
sub POVLEFT 	{$_[0]->{INFO}{POVLEFT}}





1;
__END__

=head1 NAME

Win32::MultiMedia::Joystick - Perl extension for Win32 Joystick APIs

=head1 SYNOPSIS

   use Win32::MultiMedia::Joystick;
   my $joy1 = Win32::MultiMedia::Joystick->new();
   $joy1->update;
   print $joy1->X,"\t",$joy1->Y,"\t";
   print $joy1->Z,"\n" if $joy1->hasZ;
   print $joy1->B1;


=head1 DESCRIPTION

	Win32::MultiMedia::Joystick 


=head1  OO Methods


=over 4



=item     B<new(?number?,?raw?)>


     my $joy1 = Win32::MultiMedia::Joystick->new();

     Creates a new Win32::MultiMedia::Joystick object 
     and populates the joystick capabilities info.
      Parameters:
        number: specifies which joystick to use. 
                defaults to JOY1 (which is actually 0)
        raw: if non 0, causes the access method to return 
              non calibrated data. defaults to 0

      Return value:
        A new Win32::MultiMedia::Joystick object or undef
        on failure

=item     B<id>


    Returns the JOYSTICKIDx value.

=item     B<setRaw>(bool)


    $joy1->setRaw(1) turns on raw mode.
    $joy1->setRaw(0) turns off raw mode.

=item     B<isUsingRaw>


    Returns true if the joystick object returns uncalibrated 
     data.

=item     B<update>


     Reads the joystick information from the system.
      Parameters: none
      Return value:
        1 on success: The info is updated.
        0 on failure: The info is untouched.
        Failure can be caused by a read attempt while the 
        system is updating the joystick info.

=item     B<error>


   print $joy->error;
   Returns the last error generated.
   In scalar context, returns the error number 
      (compare with JOYERR_x to determine cause)
   In array context, returns an array of the error number
     and text.

=item     B<setCapture>(hwnd, period, changed)


  $joy1->setCapture(hwnd, period, changed)
    Tells the joystick to send messages to the Win32 window 
    given by hwnd.
  Returns undef on failure.

=item     B<releaseCapture>


  $joy1->releaseCapture;
    Releases the joystick from the previous capture.
  Returns undef on failure.

=item     B<threshold>(?num?)


  Used with the "Capture" methods above.
  When called without parameters, it returns the current threshold
   value.
     print $joy1->threshold;
  When called with one parameter, sets the threshold value 
   for the captured joystick.
     $joy1->threshold(5);
  Returns undef on failure.



=head2 Methods for joystick values


=item      B<X>


   Returns the X value.

=item      B<Y>


   Returns the Y value.

=item      B<Z>


   Returns the Z value.

=item      B<R>


   Returns the R value.

=item      B<U>


   Returns the U value.

=item      B<V>


   Returns the V value.


=item      B<ButtonNumber>

   Returns the number of the button currently pressed.

=item      B<Bx>


   Returns true if button 'x' is pressed.
    'x' is in the range of 1 to 32
     ie.  $joy1->B1;

=item      B<Buttons>

   Returns the raw button data. Must be logically &'d with
     one of the JOY_BUTTONx constants.

=item      B<POV>


   Returns point of view (POV) value.
     This is a value in the range of 0 to 35,900 which 
     is the angle*100 or -1 if centered.
     if $joy->hasPOVCTS is true, the value is continuous.

=item      B<POVCENTERED>


   Returns true if POV is centered.

=item      B<POVFORWARD>


   Returns true if POV is forward.

=item      B<POVRIGHT>


   Returns true if POV is right.

=item      B<POVBACKWARD>


   Returns true if POV is backward.

=item      B<POVLEFT>


   Returns true if POV is left.




=head2 Methods for Joystick capabilities

=item      B<hasZ>


   Returns true if the joystick has a "Z" dimension.

=item      B<hasR>


   Returns true if the joystick has a "R" (4th or rudder) dimension.

=item      B<hasU>


   Returns true if the joystick has a "U" (5th) dimension.

=item      B<hasV>


   Returns true if the joystick has a "V" (6th) dimension.


=item      B<MaxAxes>


   Returns the maximum axis possible.

=item      B<NumAxes>


   Returns the actual number of axis.

=item      B<MaxButtons>


   Returns the maximum buttons possible.

=item      B<NumButtons>


   Returns the actual number of buttons.

=item      B<PeriodMax>


   Returns the maximum period

=item      B<PeriodMin>


   Returns the minimum period

=item      B<Xmax>


   Returns the max "X" value possible.


=item      B<Xmin>


   Returns the min "X" value possible.


=item      B<Ymax>


   Returns the max "Y" value possible.

=item      B<Ymin>


   Returns the min "Y" value possible.

=item      B<Zmax>


   Returns the max "Z" value possible.

=item      B<Zmin>


   Returns the min "Z" value possible


=item      B<Rmax>


   Returns the max "R" value possible.

=item      B<Rmin>


   Returns the min "R" value possible

=item      B<Umax>


   Returns the max "U" value possible.

=item      B<Umin>


   Returns the min "U" value possible

=item      B<Vmax>


   Returns the max "V" value possible.

=item      B<Vmin>


   Returns the min "V" value possible


=item      B<hasPOV>


   Returns true if the joystick has point of view.

=item      B<hasPOV4DIR>


   Returns true if the joystick reports descrete values for 
   point of view. 

=item      B<hasPOVCTS>


   Returns true if the joystick report continuous values for 

=item      B<ProductID>


   Returns the product ID of the joystick.

=item      B<ManufacturerID>


   Returns the manufacturer ID of the joystick.

=item      B<Name>


   Returns the product name of the joystick.


=head1 Non-OO interface



=item     B<GetInfo>(JOYSTICKID,?raw?)

   Returns a reference to a hash containing all the info
   listed in the Methods for joystick values section 
   above. undef on failure.
   if raw is given and non 0, causes the access mathod to return 
              non calibrated data. defaults to 0


=item     B<GetNumDevs>


   Returns the number of joysticks supported by the system,
     not the number of joysticks.

=item     B<GetThreshold>(JOYSTICKID)


  Identical to the $joy1->threshold OO method.

=item     B<SetThreshold>(JOYSTICKID)


  Identical to the $joy1->threshold($value) OO method.

=item     B<SetCapture>(hwnd, JOYSTICKID, Period, Changed)


  Identical to the $joy1->setCapture(...) OO method.

=item     B<ReleaseCapture>(JOYSTICKID)


  Identical to the $joy1->releaseCapture OO method.

=head1  Example


   #This loop prints out the X and Y values until Button1 is pressed
   use Win32::MultiMedia::Joystick;
   my $joy1 = Win32::MultiMedia::Joystick->new(); #defaults to JOY1
   while (!$joy1->B1)
   {
      $joy1->update;  #needs to be in the loop 
      print $joy1->X,",",$joy1->Y,"\n";
   }


   # non-OO
   use Win32::MultiMedia::Joystick qw(:direct :error);

   my $te = GetDevCaps(JOY1);
   while (my($k,$v)=each %$te)
   {
      print "$k\t\t= $v\n";
   }
   
   my $ji = GetInfo(JOY1);
   while (my($k,$v)=each %$ji)
   {
      print "$k\t\t= $v\n";
   }


=back


=head1 EXPORT


   JOY1:  ID number of the first joystick
   JOY2:  ID number of the second joystick

  Things you can export:

   :direct       Exports the non-OO functions

   Constants   
   :error        Exports the error constants
   :button       Exports the constants for the 'Buttons' method.
   :pov          Exports the POV constants
   :messages     Exports the messages for captured joysticks

=head1 AUTHOR

	Tom Kliethermes  tomk@informix.com

=head1 SEE ALSO

perl(1),  Microsoft Windows Platform SDK.

=cut








