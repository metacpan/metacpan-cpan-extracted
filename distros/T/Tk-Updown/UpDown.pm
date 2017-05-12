package Tk::UpDown;

use Tk;
use strict;

use base qw(Tk::Derived Tk::Frame);
use vars qw($VERSION);
use Carp;

$VERSION = '0.01';

Tk::Widget->Construct('UpDown');

sub new()
{
	my ($Class) = (shift);

	my $Object = $Class->SUPER::new(@_);
	$Object->{_CurValue} = $Object->{_InitValue};
	
	if($Object->{_InitValue} > $Object->{_EndValue})
	{
		croak "Tk::Error initdigit Should less than enddigit\n";
	}
	return $Object;
}

sub Populate()
{
	my ($this)  = (shift);

    eval
       {
        my $Bitmask = pack
           (
            "b8"x8,
            "..........",
            ".11111111.",
            "..111111..",
            "..111111..",
            "...1111...",
            "...1111...",
            "....11....",
            "....11....",
           );

        $this->Window()->DefineBitmap
           (
            'downtriangle' => 8, 8, $Bitmask
           );
       };

    eval
       {
        my $Bitmask = pack
           (
            "b8"x8,
            "....11....",
            "....11....",
            "...1111...",
            "...1111...",
            "..111111..",
            "..111111..",
            ".11111111.",
            "..........",
           );

        $this->Window()->DefineBitmap
           (
            'uptriangle' => 8, 8, $Bitmask
           );
       };

	my $Num_Entry = $this->Component
       (
        'Entry' => 'Entry',
		'-justify' => 'right',
	   	'-state' => 'disabled',
        '-highlightthickness' => 1,
        '-borderwidth' => 0,
        '-relief' => 'flat',
        '-takefocus' => 1,
        '-width' => 10,
		'-textvariable' => \$this->{_CurValue},
       );

    my $Up_Button = $this->Component
       (
        'Button' => 'Button',
        '-bitmap' => 'uptriangle',
        '-command' => sub {$this->Increment();},
        '-highlightthickness' => 1,
        '-relief' => 'raised',
        '-borderwidth' => 1,
        '-takefocus' => 1,
        '-width' => 0,
       );

    my $Down_Button = $this->Component
       (
        'Button' => 'Button',
        '-bitmap' => 'downtriangle',
        '-command' => sub {$this->Decrement();},
        '-highlightthickness' => 1,
        '-relief' => 'raised',
        '-borderwidth' => 1,
        '-takefocus' => 1,
        '-width' => 0,
       );

    $Num_Entry->pack
       (
        '-expand' => 'true',
        '-fill' => 'both',
        '-anchor' => 'nw',
        '-side' => 'left',
        '-ipadx' => 0,
        '-ipady' => 0,
        '-padx' => 0,
        '-pady' => 0,
       );

    $Up_Button->pack
       (
        '-side' => 'top',
        '-anchor' => 'ne',
        '-ipadx' => 0,
        '-ipady' => 0,
        '-padx' => 0,
        '-pady' => 0,
       );

    $Down_Button->pack
       (
        '-side' => 'bottom',
        '-anchor' => 'se',
        '-ipadx' => 0,
        '-ipady' => 0,
        '-padx' => 0,
        '-pady' => 0,
       );

    $this->ConfigSpecs
       (
        '-background' => [['SELF', 'METHOD', $Num_Entry], 'background', 'Background', 'white'],
        '-foreground' => [['SELF', 'METHOD', $Num_Entry], 'foreground', 'Foreground', 'black'],
        '-relief' => [['SELF', 'METHOD', $Up_Button, $Down_Button], 'relief', 'Relief'],
        '-cursor' => [['SELF', 'METHOD', $Num_Entry], 'cursor', 'Cursor'],
        '-height' => [['SELF', 'METHOD', $Num_Entry, $Up_Button, $Down_Button], 'height', 'height', 5],
        '-width' => [['SELF', 'METHOD', $Num_Entry], 'width', 'Width', 10],
        '-borderwidth' => [['SELF', $Up_Button, $Down_Button], 'borderwidth', 'BorderWidth', 1],
        '-state' => [['SELF', 'METHOD', $Up_Button, $Down_Button], 'state', 'State', 'normal'],
		'-initdigit' => ['METHOD', 'initdigit', 'Initdigit', 1],
		'-enddigit' => ['METHOD', 'enddigit', 'Enddigit', 100],
		'-beep' => ['METHOD', 'beep', 'Beep', 1],
		'-step' => ['METHOD', 'step', 'Step', 1],
        '-bg' => '-background',
        '-fg' => '-foreground',
       );
	$this->SUPER::Populate (@_);

	return $this;
}

sub Class()
{
	return $_[0]->{_Class};	
}

sub Window()
{
	my ($this) = (shift);

	return $this->parent;
}

sub step()
{
	my ($this) = (shift);
	
	if($_[0] < 0)
	{
		die "Illegal Value for -step\n";
	}
	$this->{_StepValue} = $_[0];
}

sub enddigit()
{
	my ($this) = (shift);
	
	if($_[0] !~ /^\d+/)
	{
		die "Illegal Value for -enddigit\n";
	}
	$this->{_EndValue} = $_[0];
}

sub initdigit()
{
	my ($this) = (shift);

	if($_[0] !~ /^\d+/)
	{
		die "Illegal Value for -initdigit\n";
	}
	$this->{_InitValue} = $_[0];
}

sub beep()
{
	my ($this) = (shift);
	
	if($_[0] < 0)
	{
		die "Illegal Value for -beep\n";
	}
	$this->{_Beep} = $_[0];
}

sub Increment()
{
	my ($this) = (shift);

	if(($this->{_CurValue} + $this->{_StepValue}) > $this->{_EndValue})
	{
		if($this->{_Beep} == 1)
		{
			$this->Window()->bell();
		}
	}
	else
	{
		$this->{_CurValue} += $this->{_StepValue};
	}
}

sub Decrement()
{
	my ($this) = (shift);

	if(($this->{_CurValue} - $this->{_StepValue}) < $this->{_InitValue})
	{
		if($this->{_Beep} == 1)
		{
			$this->Window()->bell();
		}
	}
	else
	{
		$this->{_CurValue} -= $this->{_StepValue};
	}
}

1;

__END__

=cut

=head1 NAME

   Tk::UpDown - Number Navigation Widget

=head1 SYNOPSIS

   $updown = $parent->UpDown(?options?);


=head1 STRANDARD OPTIONS

   -background | -bg, -foreground | -fg, -state, -width, -height, -relief, -cursor, -borderwidth
   

=head1 WIDGET SPECIFIC OPTIONS
	
    Name   :   initdigit

    Class  :   InitDigit

    Switch :   -initdigit

         Specifies the Starting Value for the Number List.

    Name   :  enddigit

    Class  :  EndDigit

    Switch :  -enddigit

         Specifies the Endpoint for the Number List.

    Name   :  step

    Class  :  Step

    Switch :  -step

         Specifies the Incremental or Decremental Value for Navigation.

    Name   :  beep

    Class  :  Beep

    Switch :  -beep

         Specifies whether to enable bell when reaches the Boundary while Navigation.
	
=head1 DESCRIPTION

    A UpDown Navigation Control for Numbers List

=head1 Example

        use Tk;
        use UpDown;
        
        my $MainWindow = MainWindow->new();
        $UpDown = $MainWindow->UpDown
		(
		  -bg => 'cyan', 
		  -fg => 'brown', 
		  -initdigit => 1, 
		  -enddigit => 10, 
		  -step => 1, 
		  -beep => 1
		);

        $UpDown->pack();
        
        MainLoop;

=head1 AUTHORS

SanjaySen.P , palash_bksys@yahoo.com

=cut
