package Tk::YANoteBook::NameTab;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.08';

use Tk;
use base qw(Tk::Derived Tk::Frame);
Construct Tk::Widget 'NameTab';

sub Populate {
	my ($self,$args) = @_;
	
	my $closebutton = delete $args->{'-closebutton'};
	$closebutton = 0 unless defined $closebutton;

	my $padx = delete $args->{'-tpadx'};
	$padx = 1 unless defined $padx;

	my $pady = delete $args->{'-tpady'};
	$pady = 1 unless defined $pady;

	my $closeimage;
	if ($closebutton) {
		$closeimage = delete $args->{'-closeimage'};
		$closeimage = $self->Pixmap(-file => Tk->findINC('close_icon.xpm')) unless defined $closeimage;
	}

	$self->SUPER::Populate($args);
	my $l = $self->Label(
	)->pack(
		-side => 'left',
		-expand => 1,
		-fill => 'both',
		-padx => $padx,
		-pady => $pady,
	);
	$self->Advertise('Label' => $l);

	$self->bind('<Motion>', [$self, 'TabMotion', Ev('x'), Ev('y')]);
	$l->bind('<Motion>', [$self, 'ItemMotion', $l, Ev('x'), Ev('y')]);

	$self->bind('<Button-1>', [$self, 'OnClick']);
	$l->bind('<Button-1>', [$self, 'OnClick']);

	$self->bind('<ButtonRelease-1>', [$self, 'OnRelease']);
	$l->bind('<ButtonRelease-1>', [$self, 'OnRelease']);
	
	my $b;
	if ($closebutton) {
		$b = $self->Button(
			-image => $closeimage,
			-command => ['TabClose', $self],
			-relief => 'flat',
			-highlightthickness => 0,
		)->pack(
			-side => 'right',
			-padx => 1,
			-pady => 1,
		);
		$b->bind('<Motion>', [$self, 'ItemMotion', $b, Ev('x'), Ev('y')]);
	}
	
	my @conf = ();
	if (defined $b) {
		@conf = (
			-background => [[$self, $l, $b], 'background', 'Background',],
		)
	} else {
		@conf = (
			-background => [[$self, $l], 'background', 'Background',]
		)
	}
	
	$self->ConfigSpecs(@conf,
		-borderwidth => [ [$self ], 'borderWidth', 'BorderWidth', 1],
		-name => ['PASSIVE', undef, undef, ''],
		-clickcall => ['CALLBACK', undef, undef, sub {}],
		-closecall => ['CALLBACK', undef, undef, sub {}],
		-motioncall => ['CALLBACK', undef, undef, sub {}],
		-releasecall => ['CALLBACK', undef, undef, sub {}],
		-relief => [ [$self ], 'relief', 'Relief',],
		-title => [{-text => $l}],
		-titleimg => [{-image => $l}],
		DEFAULT => [$l],
	);
}

sub ItemMotion {
	my ($self, $item, $x, $y) = @_;
	$x = $x + $item->x;
	$y = $y + $item->y;
	$self->TabMotion($x, $y);
}

sub OnClick {
	my $self = shift;
	my $name = $self->cget('-name');
	$self->Callback('-clickcall', $name);
}

sub OnRelease {
	my $self = shift;
	my $name = $self->cget('-name');
	$self->Callback('-releasecall', $name);
}

sub TabClose {
	my $self = shift;
	$self->Callback('-closecall', $self->cget('-name'));
}

sub TabMotion {
	my ($self, $x, $y) = @_;
	my $name = $self->cget('-name');
	$self->Callback('-motioncall', $name, $x, $y);
}

1;


