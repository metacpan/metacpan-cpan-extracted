package Tk::YANoteBook::NameTab;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.10';

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

	my $i = $self->Label;
	$self->Advertise('Indicator' => $i);

	$self->bind('<Motion>', [$self, 'TabMotion', Ev('x'), Ev('y')]);
	$l->bind('<Motion>', [$self, 'ItemMotion', $l, Ev('x'), Ev('y')]);
	$i->bind('<Motion>', [$self, 'ItemMotion', $l, Ev('x'), Ev('y')]);

	$self->bind('<Button-1>', [$self, 'OnClick']);
	$l->bind('<Button-1>', [$self, 'OnClick']);
	$i->bind('<Button-1>', [$self, 'OnClick']);

	$self->bind('<ButtonRelease-1>', [$self, 'OnRelease']);
	$l->bind('<ButtonRelease-1>', [$self, 'OnRelease']);
	$i->bind('<ButtonRelease-1>', [$self, 'OnRelease']);
	
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
			-background => [[$self, $i, $l, $b], 'background', 'Background',],
		)
	} else {
		@conf = (
			-background => [[$self, $i, $l], 'background', 'Background',]
		)
	}
	
	$self->ConfigSpecs(@conf,
		-borderwidth => [ [$self ], 'borderWidth', 'BorderWidth', 1],
		-name => ['PASSIVE', undef, undef, ''],
		-clickcall => ['CALLBACK', undef, undef, sub {}],
		-closecall => ['CALLBACK', undef, undef, sub {}],
		-indicatorimage => [{-image => $i}],
		-indicatortext => [{-text => $i}],
		-motioncall => ['CALLBACK', undef, undef, sub {}],
		-releasecall => ['CALLBACK', undef, undef, sub {}],
		-relief => [ [$self ], 'relief', 'Relief',],
		-title => [{-text => $l}],
		-titleimg => [{-image => $l}],
		DEFAULT => [$l],
	);
}

sub Indicator {
	my ($self, $flag) = @_;
	my $i = $self->Subwidget('Indicator');
	if (defined $flag) {
		if ($flag) {
			$i->pack(
				-before => $self->Subwidget('Label'),
				-side => 'left',
				-padx => 1,
				-pady => 1,
			)
		} else {
			$i->packForget
		}
	}
	return $i->ismapped
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


