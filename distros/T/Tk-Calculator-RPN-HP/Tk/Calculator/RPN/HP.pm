$Tk::Calculator::RPN::HP::VERSION = '1.2';

package Tk::Calculator::RPN::HP;

# OO base class and Exporter module for HP RPN calculators.

use Exporter;
use base qw/Exporter/;
push @EXPORT, qw/
    $BLUE $BLUE_DARKER
    $GRAY $GRAY_LIGHTER $GRAY_LIGHTEST
    $ORANGE $PI $ROLD $ROLU $SILVER $STACKM  $SWAP
/;
push @EXPORT, qw/$AC $AS $AT $CO $EX $LG $LN $RP $SI $SQ $TA $TX/;
push @EXPORT, qw/$AD $AN $DD $DM $DV $IO $ML $SB $XR $YX/;

use POSIX;
use Tk::widgets qw /Compound/;
use base qw/Tk::Frame/;
Construct Tk::Widget 'Calculator';
use subs qw/mode/;
use strict;

use constant E     => 2.7182818;# e
use constant PI    => 3.1415926;# pi
use constant D2R   => PI / 180;	# degrees per radian
our $ROOT = 'Calculator/RPN/images';

# Exported global constants and mathematical functions.

our $BLUE;			# color
our $BLUE_DARKER;		# color
our $GRAY;			# color
our $GRAY_LIGHTER;		# color
our $GRAY_LIGHTEST;		# color
our $ORANGE;			# color
our $PI;			# image of pi
our $ROLD;			# roll stack up image
our $ROLU;			# roll stack down image
our $SILVER;			# color
our $STACKM;			# maximum stack length
our $SWAP;			# swap X/Y image

our $AC;			# arccosine
our $AS;			# arcsine
our $AT;			# arctangent
our $CO;			# cosine
our $EX;			# e**x
our $LG;			# log10
our $LN;			# natural logarithm
our $RP;			# reciprocal
our $SI;			# sine
our $SQ;			# square root
our $TA;			# tangent
our $TX;			# 10**x

our $AD;			# add
our $AN;			# AND
our $DD;			# double divide
our $DM;			# double multiply
our $DV;			# divide
our $IO;			# inclusive OR
our $ML;			# multiply
our $SB;			# subtract
our $XR;			# exclusive OR
our $YX;			# exponentiation

sub ClassInit {

    my ($class, $mw) = @_;

    # Exported global constants.

    $BLUE          = 'steelblue1';
    $BLUE_DARKER   = 'steelblue';
    $GRAY          = 'gray25';
    $GRAY_LIGHTER  = 'gray31';
    $GRAY_LIGHTEST = 'gray40';
    $ORANGE        = 'orange';
    $SILVER        = '#ef5bef5bef5b';
    $STACKM        = 4 - 1;

    # Exported mathematical functions expecting one operand,
    # X from the RPN stack.

    $AC = sub {acos mode(@_)};	# arccosine
    $AS = sub {asin mode(@_)};	# arcsine
    $AT = sub {atan mode(@_)};	# arctangent
    $CO = sub {sin mode(@_)};	# cosine
    $EX = sub {E ** $_[0]};	# e**x
    $LG = sub {log10 $_[0]};	# log10
    $LN = sub {log $_[0]};	# natural logarithm
    $RP = sub {1 / $_[0]};	# reciprocal
    $SI = sub {sin mode(@_)};	# sine
    $SQ = sub {sqrt $_[0]};	# square root
    $TA = sub {tan mode(@_)};	# tangent
    $TX = sub {10 ** $_[0]};	# 10**x

    # Exported mathematical functions expecting two operands,
    # X and Y from the RPN stack.

    $AD = sub {$_[1] +  $_[0]};	# addition
    $AN = sub {$_[1] &  $_[0]};	# AND
    $DD = sub {$_[1] /  $_[0]};	# double divide
    $DM = sub {$_[1] *  $_[0]};	# double multiply
    $DV = sub {$_[1] /  $_[0]};	# division
    $IO = sub {$_[1] |  $_[0]};	# inclusive OR
    $ML = sub {$_[1] *  $_[0]};	# multiplication
    $SB = sub {$_[1] -  $_[0]};	# subtraction
    $XR = sub {$_[1] ^  $_[0]};	# exclusive OR
    $YX = sub {$_[1] ** $_[0]};	# exponentiation

    # Exported images.

    my (@cargs) = (-foreground => $BLUE, -background => $GRAY_LIGHTER);

    $PI = $mw->Bitmap(-file => Tk->findINC("$ROOT/pi.xbm"), @cargs);

    $ROLU = $mw->Compound;
    $ROLU->Text(-text => 'R', -foreground => $BLUE);
    $ROLU->Image(-image => $mw->Bitmap(-file => Tk->findINC("$ROOT/rolu.xbm"), @cargs));

    @cargs = (-foreground => 'white', -background => $GRAY);

    $ROLD = $mw->Compound;
    $ROLD->Text(-text => 'R', -foreground => 'white');
    $ROLD->Image(-image => $mw->Bitmap(-file => Tk->findINC("$ROOT/rold.xbm"), @cargs));

    $SWAP = $mw->Compound;
    $SWAP->Text(-text => 'X', -foreground => 'white');
    $SWAP->Image(-image => $mw->Bitmap(-file => Tk->findINC("$ROOT/swap.xbm"), @cargs));
    $SWAP->Text(-text => 'Y', -foreground => 'white');

    $class->SUPER::ClassInit($mw);

} # end ClassInit

sub Populate {

    # Populate() for this base class is rather tricky because it re-blesses
    # the incoming object (whether this is good style is another question).
    # It does this so that method lookups are dispatched to the new class
    # based on the type of calculator.  This also means that superclass
    # lookups are found here, the HP RPN base class.
    #
    # This presents one problem - ClassInit() is never called for the new
    # subclass.  We handle this situation just like a C widget, and invoke
    # InitClass on the re-blessed class, which eventually calls ClassInit.

    my ($self, $args) = @_;

    $self->SUPER::Populate($args);

    $self->{TYPE}       = delete $args->{-type};
    die "HP calculator type not specified." unless $self->{TYPE};

    mkdir $^O eq "MSWin32" ? 'C:\.hp' : "$ENV{HOME}/.hp", 0755;

    my $calc = 'Tk::Calculator::RPN::HP_' . uc($self->{TYPE});
    eval "require $calc";
    die "Tk::Calculator::RPN::HP::HP.pm, error loading '$calc': $@" if $@;
    bless $self, $calc;

    $calc->InitClass($self->MainWindow); # called once/class/MainWindow

    # Instance pre-initialization.

    $self->{CLRX}       = 0;   # 1 IFF clear X before inserting next key
    $self->{F_PRESSED}  = 0;   # F-key modifier pressed
    $self->{G_PRESSED}  = 0;   # G-key modifier pressed
    $self->{ONOFF}      = 0;   # 1 IFF calculator on
    $self->{PUSHX}      = 0;   # 1 IFF push X before inserting next key
    $self->{MODE}       = 0;   # 0 = degress, 1 = radians
    $self->{PB}         = delete $args->{-progressbar};	# possible ProgressBar
    $self->{XV}         = ' '; # current display (X) value
    $self->clr;                # clear entire stack

    # Build the calculator.

    $self->{PB_PERCENT} = 0;
    $self->Populate($args);
    $self->{PB}->set($self->{PB_PERCENT} = 100) if $self->{PB};

} # end Populate

sub build_help_button {

    # Create the ? Button common to all calculator types.

    my ($self, $parent, $help) = @_;

    my $quest = $parent->Button(
        -text               => '?',
	-font               => '6x9',
        -relief             => 'flat',
	-highlightthickness => 0,
	-background         => $BLUE,	
        -borderwidth        => 0,
        -pady               => 0,
        -command            => sub {$help->deiconify},
    );
    $quest->bind('<2>' => sub {
	my (@register) = ('(X)', '(Y)', '(Z)', '(T)');
	print "\n";
        for (my $i = $STACKM; $i >= 0; $i--) {
	    print "stack+$i $register[$i] : '", $self->{STACK}[$i], "'\n";
	}
    });

    $self->{PB}->set($self->{PB_PERCENT} += 10) if $self->{PB};

    return $quest;

} # end build_help_button

sub build_help_window {

    # Called by ClassInit() to build a help window shared by all subclass instances.

    my ($class, $mw) = @_;

    my $help = $mw->Toplevel;
    $help->withdraw;
    $help->title('HP 21 Help');
    $help->protocol('WM_DELETE_WINDOW' => sub {});

    my $frame = $help->Frame->pack;

    my ($type) = $class =~ /.*::(.*)/;
    $frame->Label(
        -image => $mw->Photo(-file => Tk->findINC("$ROOT/" . lc($type) . '-back.gif')),
    )->pack;

    $frame->Label(
        -text   => '? <B1> displays this window',
        -relief => 'ridge',
    )->pack(qw/-expand 1 -fill both/);

    $frame->Label(
        -text   => '? <B2> prints the stack',
        -relief => 'ridge',
    )->pack(qw/-expand 1 -fill both/);
    $frame->Button(
        -text             => 'Close', 
        -command          => sub {$help->withdraw},
    )->pack(qw/-expand 1 -fill both/);

    return $help;

} # end build_help_window

sub mode {

    # Convert an argument from degees to radians, if required.

    my ($f, $mode) = @_;

    return $f if $mode;		# already in radians
    return $f * D2R;		# if degrees

} # end mode

sub set_keypad_bindings {

    # Now establish key bindings for the digits and common arithmetic
    # operations, including keypad keys.

    my ($self) = @_;

    my $mw = $self->MainWindow;

    foreach my $key ( qw/0 1 2 3 4 5 6 7 8 9/ ) {
        $mw->bind( "<Key-$key>" => [$self => 'key', $key] );
        $mw->bind( "<KP_$key>"  => [$self => 'key', $key] );
    }

    foreach my $key ( qw/period KP_Decimal/ ) {
        $mw->bind( "<$key>"     => [$self => 'key', '.'] );
    }

    foreach my $key ( qw/Return KP_Enter/ ) {
        $mw->bind( "<$key>"     =>  [$self => 'enter'] );
    }

    foreach my $key ( qw/plus KP_Add/ ) {
        $mw->bind( "<$key>"     => [$self => 'math3', $AD, undef, undef] );
    }

    foreach my $key ( qw/minus KP_Subtract/ ) {
        $mw->bind( "<$key>"     => [$self => 'math3', $SB, undef, undef] );
    }

    foreach my $key ( qw/asterisk KP_Multiply/ ) {
        $mw->bind( "<$key>"     => [$self => 'math3', $ML, undef, undef] );
    }

    foreach my $key ( qw/slash KP_Divide/ ) {
        $mw->bind( "<$key>"     => [$self => 'math3', $DV, undef, undef] );
    }

} # end set_keypad_bindings

# Function key processors common to all classes.

sub chs {			# change sign

    my ($self) = @_;

    my $s = substr($self->{STACK}[0], 0, 1);
    substr($self->{STACK}[0], 0, 1) = ($s eq '-') ? ' ' : '-';
    $self->end;

} # end chs

sub clr {			# clear stack

    my ($self) = @_;

    $self->{STACK}[$_] = ' 0.00' foreach (0 .. $STACKM);
    $self->end;

} # end clr

sub clx {			# clear x

    my ($self) = @_;

    $self->{STACK}[0] = 0;
    $self->{CLRX} = 1;
    $self->{PUSHX} = 0;
    $self->end;

} # end clx

sub end {			# key and display cleanup

    my ($self) = @_;

    $self->{F_PRESSED} = $self->{G_PRESSED} = 0;
    $self->{XV} = $self->{STACK}[0];

} # end end

sub enter {			# enter key

    my ($self) = @_;

    unshift @{$self->{STACK}}, $self->{STACK}[0];
    $#{$self->{STACK}} = $STACKM if $#{$self->{STACK}} > $STACKM;
    $self->{CLRX} = 1;
    $self->{PUSHX} = 0;
    $self->end;

} # end enter
                           
sub err {			# error

    my ($self) = @_;

    $self->bell if $self->{ONOFF};

} # end err

sub f {				# F key

    my ($self) = @_;

    $self->{F_PRESSED} = 1;

} # end f

sub g {				# G key

    my ($self) = @_;

    $self->{G_PRESSED} = 1;

} # end g

sub hpshift {			# empty HP stack

    my ($self) = @_;

    $#{$self->{STACK}} = $STACKM if $#{$self->{STACK}} > $STACKM;
    my $v = shift @{$self->{STACK}};
    $self->{STACK}[$STACKM] = $self->{STACK}[$STACKM - 1] if
	$#{$self->{STACK}} == ($STACKM - 1);

    $self->end;
    return $v;

} # end hpshift

sub key {			# process generic key clicks

    my ($self) = @_;

    shift if ref $_[0];		# toss bind() object
    my $key = $_[0];
    return unless $self->{ONOFF};
    if ($self->{F_PRESSED} or $self->{G_PRESSED}) {
	$self->bell;
	$self->end;
	return;
    }

    $self->enter if $self->{PUSHX};
    $self->{STACK}[0] = ' ' if $self->{CLRX};

    $self->{STACK}[0] .= $key;
    $self->{CLRX} = $self->{PUSHX} = 0;
    $self->end;

} # end key

sub math {			# non-G key arithmetic operations

    # math() expects one code reference to an anonymous subroutine, which
    # expects one argument, X from the RPN stack.

    my $self = shift;

    $self->{STACK}[0] = &{$_[0]}($self->{STACK}[0]);
    $self->{STACK}[0] = ' ' .  $self->{STACK}[0] if
	substr($self->{STACK}[0], 0, 1) ne '-';
    $self->{CLRX} = $self->{PUSHX} = 1;
    $self->end;

} # end math

sub math3 {			# tri-arithmetic keys

    # math3() expects three code references to anonymous subroutines, each
    # of which expects two arguments, X and Y from the RPN stack. 
    #
    # $_[0] = normal button press
    # $_[1] = "f" qualified button press
    # $_[2] = "g" qualified button press

    my ($self) = @_;

    shift if ref $_[0];		# toss bind() object
    my $math = $_[0];
    $math = $_[1] if $self->{F_PRESSED};
    $math = $_[2] if $self->{G_PRESSED};
    if (not defined $math) {
	$self->bell;
	$self->end;
	return;
    }

    my $x = $self->hpshift;
    my $y = $self->{STACK}[0];
    $self->{STACK}[0] = &{$math}($x, $y);
    $self->{STACK}[0] = ' ' .  $self->{STACK}[0]
	if substr($self->{STACK}[0], 0, 1) ne '-';
    $self->{CLRX} = $self->{PUSHX} = 1;
    $self->end;

} # end math3

sub on {			# power on/off

    my ($self, $val) = @_;

    my $rc = $self->{RCFILE};
    if ($self->{ONOFF}) {
	$self->{ONOFF} = 0;
	if (open(RC, ">$rc") or die"open write failed for '$rc': $!") {
	    foreach (reverse @{$self->{STACK}}) {
		print RC "$_\n";
	    }
	    close RC;
	}
	$self->end;
	$self->{XV} = '';
    } else {
	$self->{ONOFF} = 1;
	if (open(RC, $rc)) {
	    $self->{STACK} = [] if -s $rc;
	    while ($_ = <RC>) {
		chomp;
		unshift @{$self->{STACK}}, $_;
	    }
	    close RC;
	}
	$self->{CLRX} = $self->{PUSHX} = 1;
	$self->end;
    }

} # end on

sub pi {			# return pi

    my ($self) = @_;

    $self->enter;
    $self->{STACK}[0] = PI;
    $self->end;

} # end pi

sub roll_down {			# roll stack down

    my ($self) = @_;

    return unless $self->{ONOFF};
    push @{$self->{STACK}}, shift @{$self->{STACK}};
    $self->end;

} # end roll_down

sub roll_up {			# roll stack up

    my ($self) = @_;

    return unless $self->{ONOFF};
    unshift @{$self->{STACK}}, pop @{$self->{STACK}};
    $self->end;

} # end roll_up

sub swapxy {			# swap x and y

    my ($self) = @_;

    return unless $self->{ONOFF};
    if ($self->{F_PRESSED} or $self->{G_PRESSED}) {
	$self->bell;
	$self->end;
	return;
    }

    (@{$self->{STACK}}[0, 1]) = (@{$self->{STACK}}[1, 0]);
    $self->end;

} # end swapxy

sub trig_math {			# with degree to radian conversion

    # trig_math() expects one code reference to an anonymous subroutine, which
    # expects one argument, X from the RPN stack. Convert degrees to radians
    # as appropriate.

    my $self = shift;

    $self->{STACK}[0] = &{$_[0]}($self->{STACK}[0], $self->{MODE});
    $self->{STACK}[0] = ' ' .  $self->{STACK}[0] if
	substr($self->{STACK}[0], 0, 1) ne '-';
    $self->{CLRX} = $self->{PUSHX} = 1;
    $self->end;

} # end trig_math

package Tk::Calculator::RPN::HP::Key3_16C;

# Composite mega-widget Key3 - 3 operators per key.

use Tk::widgets qw/Frame/;
use base qw/Tk::Frame/;
Construct Tk::Calculator::RPN::HP 'Key3_16C';

sub Populate {

    my ($self, $args) = @_;

    my $topl = delete $args->{-topl};
    my $butl = delete $args->{-butl};
    my $botl = delete $args->{-botl};

    $self->SUPER::Populate($args);

    my (@pl) = qw/-side top -expand yes -fill both/;
    $self->{topl} = $self->Label(-text  => $topl)->pack(@pl);
    $self->{topl}->configure(    -image => $topl) if ref($topl);

    $self->{butl} = $self->Button(
        -text        => $butl,
        -borderwidth => 2,
    )->pack(@pl);
    $self->{butl}->configure(    -image => $butl) if ref($butl);

    $self->{botl} = $self->Label(-text  => $botl)->pack(@pl);
    $self->{botl}->configure(    -image => $botl) if ref($botl);

    $self->pack(qw/-side left -expand 1 -fill both -padx 3 -pady 3/);

    $self->ConfigSpecs(
        -background => [qw/METHOD         background background yellow/],
        -command    => [$self->{butl}, qw/command    Command/,  undef],
        -foreground => [qw/METHOD         foreground Foreground red/],
        -font       => [qw/METHOD         font       Font       fixed/],
        -width      => [qw/METHOD         width      Width      20/],
        -height     => [$self->{butl}, qw/height     Height     0/],
    );

} # end Populate

sub background {
    my ($self, $bg) = @_;
    $self->{topl}->configure(-background => $GRAY_LIGHTER);
    $self->{butl}->configure(-background => $bg);
    $self->{botl}->configure(-background => $GRAY_LIGHTER);
}

sub font {
    my ($self) = @_;
    $self->{topl}->configure(-font => [qw/arial  9 bold/]);
    $self->{butl}->configure(-font => [qw/arial 10 bold/]);
    $self->{botl}->configure(-font => [qw/arial  9 bold/]);
}

sub foreground {
    my ($self) = @_;
    $self->{topl}->configure(-foreground => $ORANGE);
    my $text = $self->{butl}->cget(-text);
    my $fg = ($text =~ /^[fg]{1}$/) ? 'black' : 'white';
    $self->{butl}->configure(-foreground => $fg);
    $self->{botl}->configure(-foreground => $BLUE);
}

sub width {
    my ($self) = @_;
    $self->{topl}->configure(-width => 6);
    $self->{butl}->configure(-width => 3);
    $self->{botl}->configure(-width => 4);
}

package Tk::Calculator::RPN::HP::Key2_21;

# Composite mega-widget Key2 - 2 operators per key.

use Tk::widgets qw/Frame/;
use base qw/Tk::Frame/;
Construct Tk::Calculator::RPN::HP 'Key2_21';

sub Populate {

    my ($self, $args) = @_;

    my $butl = delete $args->{-butl};
    my $botl = delete $args->{-botl};

    $self->SUPER::Populate($args);

    my (@pl) = qw/-side top -expand yes -fill both/;

    $self->{butl} = $self->Button(
        -text        => $butl,
        -borderwidth => 2,
    )->pack(@pl);
    $self->{butl}->configure(    -image => $butl) if ref($butl);

    $self->{botl} = $self->Label(-text  => $botl)->pack(@pl);
    $self->{botl}->configure(    -image => $botl) if ref($botl);

    $self->pack(qw/-side left -expand 1 -fill both -padx 3 -pady 3/);

    $self->ConfigSpecs(
        -background => [qw/METHOD         background background yellow/],
        -command    => [$self->{butl}, qw/command    Command/,  undef],
        -foreground => [qw/METHOD         foreground Foreground red/],
        -font       => [qw/METHOD         font       Font       fixed/],
        -width      => [qw/METHOD         width      Width      20/],
        -height     => [$self->{butl}, qw/height     Height     0/],
    );

} # end Populate

sub background {
    my ($self, $bg) = @_;
    my $text = $self->{butl}->cget(-text);
    $bg = $BLUE if $text eq 'BLUE';
    $self->{butl}->configure(-background => $bg);
    $self->{botl}->configure(-background => $GRAY_LIGHTER);
}

sub font {
    my ($self) = @_;
    $self->{butl}->configure(-font => [qw/arial 10 bold/]);
    $self->{botl}->configure(-font => [qw/arial  9 bold/]);
}

sub foreground {
    my ($self) = @_;
    my $text = $self->{butl}->cget(-text);
    my $fg = ($text =~ /^[\.\-\+\/x0123456789]$/ or
	      $text eq 'DSP') ? 'black' : 'white';
    $fg = $BLUE if $text eq 'BLUE';
    $self->{butl}->configure(-foreground => $fg);
    $self->{botl}->configure(-foreground => $BLUE);
}

sub width {
    my ($self) = @_;
    $self->{butl}->configure(-width => 3);
    $self->{botl}->configure(-width => 4);
}

1;
__END__

=head1 NAME

Tk::Calculator::RPN::HP - Hewlett-Packard RPN calculators

=head1 SYNOPSIS

 use Tk::Calculator::RPN::HP;
 $mw->Calculator(
     -type => '21' | '16c' 
 )->pack;

=head1 DESCRIPTION

Tk::Calculator::RPN::HP is the OO base class and Exporter module for
Perl/Tk Hewlett-Packard Reverse Polish Notation (RPN) calculators.  As
a base class it provides methods common to all calculators; for
instance, stack manipulation, function evaluation, and instance
creation activities.  As an exporter of data, it provides global
variables and function subroutine definitions.

Tk::Calculator::RPN::HP provides a single constructor, B<Calculator>,
as shown in the B<SYNOPSIS> section.

Tk::Calculator::RPN::HP provides a B<Populate> method implicity used
by all calculator subclasses. The only option that B<Populate> requires
is I<-type>, the type of calculator.  Given I<-type>, B<Populate> loads the
appropriate module, performs common instance pre-initialization, and then
calls out to the subclass' B<Populate> method to create the actual
calculator.

Subclasses of Tk::Calculator::RPN::HP have this basic structure:

 $Tk::Calculator::RPN::HP_21::VERSION = '1.2';

 package Tk::Calculator::RPN::HP_21;

 use Tk::widgets qw/SlideSwitch/;
 use Tk::Calculator::RPN::HP;
 use base qw/Tk::Calculator::RPN::HP/;
 use strict;

 our $HELP;

 sub ClassInit {

     my ($class, $mw) = @_;

     $HELP = $class->build_help_window($mw);
     $class->SUPER::ClassInit($mw);

 } # end ClassInit

 sub Populate {

     my ($self, $args) = @_;

 ...

    $self->build_help_button($frame1, $HELP)->pack(qw/-side left/);
 
 ...

 } # end Populate

 # Function key processors.

 sub clxclr {

     my ($self) = @_;

     return unless $self->{ONOFF};
     if ($self->{G_PRESSED}) {	# clr
	 $self->clr;
     } else {			# clx
 	$self->clx;
     }

 } # end clxclr

 1;

As you can see, the module is simply a standard Perl/Tk mega-widget.

You are required to invoke two methods, B<build_help_window> and
B<build_help_button>.  B<build_help_window> creates a Toplevel that's
exposed when the ? Button is pressed.  B<build_help_button> builds the ?
Button proper.  Because the Toplevel help window is used by all class
instances, it's typically created in B<ClassInit>.  You call
B<build_help_button> when and where you want the ? packed.

Although most calculator functions are provided by the base class,
you may find it necessary to write your own function key processors.

=head1 OPTIONS

The following option/value pairs are supported:

=over 4

=item B<-type>

The type of HP RPN calculator. Currently I<21> and I<16c> are legal
values.  There is no default, this option is required.

=item B<-progressbar>

An optional reference to a Tk::ProgressBar::Mac widget. If specified,
you are to update it periodically as the calculator takes shape.

=back

=head1 METHODS

=head2 $HELP = $class->build_help_window($mw);

Build a standard calculator help window and return a reference
to the Toplevel. You must provide an image
I<"images/hp_"> B<concat> I<lc(-type)> B<concat> I<"-back.gif"> 
(e.g. images/hp_21-back.gif) of
the back of the calculator, since there might be useful data.
B<ClassInit> is a good place to do this.

=head2 $self->build_help_button($parent, $HELP);

Build the ? Button that displays the Toplevel window created by
B<build_help_window>. I<$parent> is the Button's parent widget.

=head1 ADVERTISED WIDGETS

Component subwidgets can be accessed via the B<Subwidget> method.
This mega widget has no advertised subwidgets.

=head1 EXAMPLE

This complete example incorprates a splashscreen with a progressbar.

 use Tk;
 use Tk::Calculator::RPN::HP;
 use Tk::ProgressBar::Mac;
 use Tk::Splashscreen;

 use subs qw/main/;
 use strict;

 main;

 sub main {

     my $type = $OPT{type};

     my $mw = MainWindow->new;
     $mw->withdraw;
     $mw->title('Hewlett-Packard ' . $type . ' Calculator');
     $mw->iconname('HP ' . $type);

     my $splash = $mw->Splashscreen;
     $splash->Label(
        -text       => 'Building your HP ' . $type . ' ...',
     )->pack(qw/-fill both -expand 1/);
     my $pb = $splash->ProgressBar(-width => 300);
     $pb->pack(qw/-fill both -expand 1/);
     $splash->Label(
         -image => $mw->Photo(
	     -file => Tk->findINC('Calculator/RPN/images/hp_' . $type . '-splash.gif')
         ),
     )->pack;
     $splash->Splash;

     $mw->Calculator(
         -type        => $type, 
         -progressbar => $pb,
     )->pack;

     $splash->Destroy;
     $mw->deiconify;
    
     MainLoop;

 } # end main

=head1 AUTHOR

sol0@Lehigh.EDU

Copyright (C) 2001 - 2007, Steve Lidie. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 KEYWORDS

calculator, HP, RPN

=cut
