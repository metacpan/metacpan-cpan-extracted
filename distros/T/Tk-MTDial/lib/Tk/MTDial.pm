package Tk::MTDial;


use 5.006;
use strict;
use warnings;

=encoding UTF-8

=head1 NAME

Tk::MTDial - A MTDial Tk widget that can turn indefinitely in any direction.

=head1 VERSION

Version 0.001

=cut

$Tk::MTDial::VERSION=0.001;

=head1 SYNOPSIS

    use Tk;
    use Tk::MTDial;
    my $value=0;
    my $svalue="";
    my $mw=Tk::MainWindow->new(-title=>"MTDial test");
    my $kf=$mw->Frame->pack;
    $kf->MTDial( -width=>100, 
               -height=>100,
	       -dialsize=>49, 
	       -dialrovariable=>\$v,
	       -dialcommand=>\&cmd,
    )->pack->createMTDial;

    sub cmd {
	$value=$v;
	$svalue=sprintf "Value: %.2f Hz", $value;
	$svalue.=" OUT OF RANGE (0-10)", if $value>10 or $value < 0;
	$value=0 if $value<0;
	$value=10 if $value > 10;
    }  
    
Creates a circular MTDial that can be turned continuously and
indefinitely in any direction 

=head1 DESCRIPTION

MTDial Widget that allows the creation of circular dials that can turn
indefinitely to produce arbitrary positive or negative values.

=head1 FUNCTIONS


=head2 MTDial

Make a MTDial object and pass it initialization parameters. They may
also be set and interrogated with Tk's 'configure' and 'cget'.

=head 3 Parameters (defaults)
=over 4

=item -width (500)

=item -height (500)

=item -dialsize (250)
 
=item -dialvalue (0)

=item -dialcolor ('DarkGrey')

=item -dialborder (2)

=item -dialbordercolor1 ('grey38')

=item -dialbordercolor2 ('grey99')

=item -dialrovariable (undef)

=item -dialcommand (sub {return})

=back

=head2 createMTDial

Displays the dial, sets its initial parameters, binds the callback
routines. 

=head2 Not to be called by the user directly

=head3 ClassInit

Calls the base class initializer

=head3 Populate

Sets default values for the class parameters.

=head3 pushed

Routine called when button 1 is pushed

=head3 rotate

Routine called to rotate dial when the mouse moves

=head1 AUTHOR

W. Luis Mochán, Instituto de Ciencias Físicas, UNAM, México
C<mochan@fis.unam.mx> 

=head1 ACKNOWLEDGMENTS

This work was partially supported by DGAPA-UNAM under grants IN108413
and IN113016.   

=cut


use constant {
    PI=>4*atan2(1,1),
    id=>0.85, # indicator distance from center
    ir=>0.05,  # indicator radius
};

use base qw/Tk::Derived Tk::Canvas/;
use strict;
use warnings;

Construct Tk::Widget 'MTDial';


sub ClassInit {
    my($class, $mw) = @_;
    $class->SUPER::ClassInit($mw);
}

sub Populate {
    my($self, $args)=@_;
    my %args=%$args;
    $self->SUPER::Populate($args);
    #$self->Advertise();
    $self->ConfigSpecs(
	-width => [qw(SELF width Width), 500],
	-height=> [qw(SELF heigh Height), 500],
	-dialsize=>[qw(PASSIVE dialsize MTDialsize), 250],
	-dialvalue=>[qw(PASSIVE dialvalue MTDialvalue), 0],
	-dialcolor=>[qw(PASSIVE dialcolor MTDialcolor), 'DarkGrey'],
	-dialborder=>[qw(PASSIVE dialborder MTDialborder), 2],
	-dialbordercolor1=>[qw(PASSIVE dialbordercolor1 MTDialbordercolor1), 
			    'grey38'],
	-dialbordercolor2=>[qw(PASSIVE dialbordercolor2 MTDialbordercolor2), 
			    'grey99'],
	-dialrovariable=>[qw(PASSIVE dialrovariable MTDialrovariable), undef],
	-dialcommand=>[qw(CALLBACK dialbordercolor2 MTDialbordercolor2), 
		       sub {return}],
	DEFAULT => ['SELF']
	);
    $self->Delegates();
}

sub createMTDial {
    my ($self)=@_;
    my $ks=$self->cget(-dialsize);
    my $kc=$self->cget(-dialcolor);
    my $w=$self->cget(-width);
    my $h=$self->cget(-height);
    my $kb=$self->cget(-dialborder);
    my $kbc1=$self->cget(-dialbordercolor1);
    my $kbc2=$self->cget(-dialbordercolor2);
    $self->configure(-dialvalue=>${$self->cget(-dialrovariable)}) 
	if ref $self->cget(-dialrovariable);
    my $a=2*PI*$self->cget(-dialvalue);
    my $ca=cos($a);
    my $sa=sin($a);
    $self->create('oval', $w/2-$ks, $h/2-$ks, $w/2+$ks, $h/2+$ks,
		  -fill=>$kc, -width=>0, -tags=>[qw(dial)]); 
    $self->create('arc', $w/2-$ks, $h/2-$ks, $w/2+$ks, $h/2+$ks,
		  -style=>'arc', -start=>-135, -extent=>180, -width=>$kb,
		  -outline=>$kbc1 ); 
    $self->create('arc', $w/2-$ks, $h/2-$ks, $w/2+$ks, $h/2+$ks,
		  -style=>'arc', -start=>45, -extent=>180, -width=>$kb,
		  -outline=>$kbc2); 
    $self->create('arc', $w/2+(id*$ca - ir)*$ks, $h/2+(id*$sa - ir)*$ks,
		  $w/2+(id*$ca+ir)*$ks, $h/2+(id*$sa+ir)*$ks, 
		  -style=>'pie', -start=>-135, -extent=>180,
		  -fill=>$kbc2, -outline=>undef, -tags=>[qw(dial indicator)]); 
    $self->create('arc', $w/2+(id*$ca - ir)*$ks, $h/2+(id*$sa - ir)*$ks,
		  $w/2+(id*$ca+ir)*$ks, $h/2+(id*$sa+ir)*$ks, 
		  -style=>'pie', -start=>45, -extent=>180,
		  -fill=>$kbc1, -outline=>undef, -tags=>[qw(dial indicator)]); 
    $self->bind("dial", '<1>', [\&pushed, Tk::Ev('x'), Tk::Ev('y')]);
    $self->bind("dial", '<B1-Motion>', [\&rotate, Tk::Ev('x'), Tk::Ev('y')]);
    return $self;
}

sub pushed {
    my ($self, $x, $y)=@_;
    $self->{angle}=atan2($y-$self->cget(-height)/2, $x-$self->cget(-width)/2);
}

sub rotate {
    my ($self, $x, $y)=@_;
    my $angle=atan2($y-$self->cget(-height)/2, $x-$self->cget(-width)/2);
    my $angle0=$self->{'angle'};
    my $ks=$self->cget(-dialsize);
    $angle-=2*PI while $angle-$angle0>PI;
    $angle+=2*PI while $angle-$angle0<= - PI;
    my $kangle=2*PI*$self->cget(-dialvalue);
    my $nkangle=$kangle+$angle-$angle0;
    my $nval=$nkangle/(2*PI);
    $self->configure(-dialvalue=>$nval);
    ${$self->cget(-dialrovariable)}=$nval if ref $self->cget(-dialrovariable);
    my $deltax=id*$ks*cos($nkangle) - id*$ks*cos($kangle);
    my $deltay=id*$ks*sin($nkangle) - id*$ks*sin($kangle);
    $self->{angle}=$angle;
    $self->move('indicator', $deltax, $deltay);
    $self->Callback(-dialcommand=> $self->cget(-dialvalue));
    #my $command=$self->cget(-dialcommand);
    #$command->($self) if defined $command;
}


1;

