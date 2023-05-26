package Tk::PopList;

=head1 NAME

Tk::PopList - Popping a selection list relative to a widget

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.04';

use base qw(Tk::Derived Tk::Poplevel);

use Tk;
use Tie::Watch;

Construct Tk::Widget 'PopList';

=head1 SYNOPSIS

 require Tk::PopList;
 my $list = $window->PopList(@options,
    -values => [qw/value1 value2 value3 value4/],
    -widget => $somewidget,
 );
 $list->popUp;

=head1 DESCRIPTION

Inherits L<Tk::Poplevel>

This widget pops a listbox relative to the widget specified in the B<-widget> option.
It aligns its size and position to the widget.

You can specify B<-selectcall> to do something when you select an item. It gets the selected
item as parameter.

You can use the escape key to hide the list.
You can use the return key to select an item.

=head1 OPTIONS

=over 4

=item B<-filter>

Default value 0

Specifies if a filter entry is added. Practical for a long list of values.

=item B<-motionselect>

Default value 1

When set hoovering over a list item selects it.

=item B<-selectcall>

Callback, called when a list item is selected.

=item B<-values>

List of possible values.

=back

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;
	
	my $motionselect = delete $args->{'-motionselect'};
	$motionselect = 1 unless defined $motionselect;

	$self->SUPER::Populate($args);

	$self->{FE} = undef;
	$self->{LIST} = [];
	$self->{VALUES} = [];
	
	my $listbox = $self->Scrolled('Listbox',
		-scrollbars => 'oe',
		-listvariable => $self->{LIST},
	)->pack(-fill => 'both');
	$self->Advertise('Listbox', $listbox);
	$listbox->bind('<Escape>', [$self, 'popDown']);
	$listbox->bind('<Return>', [$self, 'Select']);
	$listbox->bind('<ButtonRelease-1>', [$self, 'Select', Ev('x'), Ev('y')]);
	$self->bind('<Motion>', [$self, 'MotionSelect', Ev('x'), Ev('y')]) if $motionselect;

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDATNS'],
		-borderwidth => ['SELF'],
		-filter => ['PASSIVE', undef, undef, 0],
		-foreground => ['SELF', 'DESCENDATNS'],
		-selectcall => ['CALLBACK', undef, undef, sub {}],
		-relief => ['SELF'],
		'-values' => ['METHOD', undef, undef, []],
		DEFAULT => [ $listbox ],
	);
}

sub calculateHeight {
	my $self = shift;
	my $list = $self->{LIST};
	my $lb = $self->Subwidget('Listbox');
	my $lheight = 10;
	if (@$list < $lheight) { $lheight = @$list }
	$lb->configure(-height => $lheight);
	my $height = $lb->reqheight;
	$height = $height + $self->{FE}->reqheight if defined $self->{FE};
	return $height
}

=item B<filter>I<($filter)>

Filters the list of values on $filter.

=cut

sub filter {
	my ($self, $filter) = @_;
	$filter = quotemeta($filter);
	my $values = $self->{VALUES};
	my @new = ();
	my $len = length($filter);
	for (@$values) {
		push @new, $_ if $_ =~ /$filter/i;
	}
	my $size = @new;
	my $list = $self->{LIST};
	#this is a hack. doing it the crude way somehow gives crashes
	while (@$list) { pop @$list }
	push @$list, @new;
}

sub MotionSelect {
	my ($self, $x, $y) = @_;
	my $list = $self->Subwidget('Listbox');
	$list->selectionClear(0, 'end');
	$list->selectionSet('@' . "$x,$y");
}

sub popDown {
	my $self = shift;
	return unless $self->ismapped;
	my $e = $self->{FE};
	if (defined $e) {	
		$e->packForget;
		$e->destroy;
		$self->{FE} = undef;
	}
	$self->SUPER::popDown;
}

sub popUp {
	my $self = shift;

	return if $self->ismapped;

	my $values = $self->{VALUES};
	my $list = $self->{LIST};
	#this is a hack. doing it the crude way somehow gives crashes
	while (@$list) { pop @$list }
	push @$list, @$values;
	
	my $e;
	if ($self->cget('-filter')) {
		my $var = 'Filter';
		$e = $self->Entry(
			-textvariable => \$var,
		);
		$e->bind('<FocusIn>', sub { $var = '' });
		$e->bind('<Escape>', [$self, 'popDown']);
		$e->bind('<Key>', sub { $self->filter($e->get) });
		$self->{FE} = $e;
	}

	$self->SUPER::popUp;

	my $lb = $self->Subwidget('Listbox');
	$lb->selectionClear(0, 'end');
	$lb->selectionSet('@0,0');
	$lb->focus;

	my @filterpack = ();
	my $direction = $self->popDirection;
	if ($direction eq 'up') {
		@filterpack = (-after => $lb);
	} elsif ($direction eq 'down') {
		@filterpack = (-before => $lb);
	}
	$e->pack(@filterpack,
		-fill => 'x'
	) if defined $e;
}

sub Select {
	my ($self, $x, $y) = @_;

	my $list = $self->Subwidget('Listbox');

	my $item = $list->get($list->curselection);
	$self->Callback('-selectcall', $item);
	$self->popDown;
}

sub values {
	my ($self, $new) = @_;
	$self->{VALUES} = $new if defined $new;
	return $self->{VALUES}
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk>

=item L<Tk::Poplevel>

=item L<Tk::Toplevel>

=item L<Tk::Listbox>

=back

=cut

1;
__END__

