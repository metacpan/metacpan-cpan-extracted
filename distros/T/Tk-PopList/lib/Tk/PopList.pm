package Tk::PopList;

=head1 NAME

Tk::PopList - Popping a selection list relative to a widget

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.14';

use base qw(Tk::Derived Tk::Poplevel);

use Tk;
require Tk::HList;

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

=item B<-nofocus>

Default value false. If set the list widget will not take focus when popping up.

=item B<-selectcall>

Callback, called when a list item is selected.

=item B<-values>

List of possible values.

=back

=head1 KEYBINDINGS

=over 4

 <Down>       Moves selection to the next item in the list.
 <End>        Moves selection to the last item in the list.
 <Escape>     Hides the poplist.
 <Home>       Moves selection to the first item in the list.
 <Return>     Selects the current selection and hides the poplist.
 <Up>         Moves selection to the previous item in the list.

=back

=cut

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;
	
	$self->SUPER::Populate($args);

	$self->{FE} = undef;
	
	my $list = $self->Scrolled('HList',
		-browsecmd => ['Select', $self],
		-command => ['Select', $self],
		-highlightthickness => 0,
		-scrollbars => 'oe',
		-selectmode => 'single',
	)->pack(-expand => 1, -fill => 'both');
	$list->bind('<Down>', [$self, 'NavDown']);
	$list->bind('<End>', [$self, 'NavLast']);
	$list->bind('<Home>', [$self, 'NavFirst']);
	$list->bind('<Up>', [$self, 'NavUp']);
	$list->bind('<Escape>', [$self, 'popDown']);
	$list->bind('<Motion>', [$self, 'MotionSelect', Ev('x'), Ev('y')]);
	
	$self->Advertise(List => $list);

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDATNS'],
		-filter => ['PASSIVE', undef, undef, 0],
		-maxheight => ['PASSIVE', undef, undef, 10],
		-motionselect => ['PASSIVE', undef, undef, 1],
		-nofocus => ['PASSIVE', undef, undef, 0],
		-selectcall => ['CALLBACK', undef, undef, sub {}],
		-values => ['METHOD', undef, undef, []],
		DEFAULT => [ $list ],
	);
}

sub calculateHeight {
	my $self = shift;
	my $list = $self->cget('-values');
	my $lb = $self->Subwidget('List');
	my $lheight = $self->cget('-maxheight');
	if (@$list < $lheight) { $lheight = @$list }
	my $font = $lb->cget('-font');
	my $lineheight = $self->fontMetrics($font, '-linespace') * 1.50;

	my $height = int($lheight * $lineheight) + 2;
	$height = $height + $self->{FE}->reqheight + 2 if defined $self->{FE};
	return $height
}

=item B<filter>I<($filter)>

Filters the list of values on $filter.

=cut

sub filter {
	my ($self, $filter) = @_;
	$filter = quotemeta($filter);
	my $l = $self->Subwidget('List');
	my $values = $self->cget('-values');
	for (0 .. @$values - 1) {
		my $val = $l->entrycget($_, '-text');
		if ($val =~ /$filter/i) {
			$l->show(-entry => $_)
		} else {
			$l->hide(-entry => $_)
		}
	}
}

sub MotionSelect {
	my ($self, $x, $y) = @_;
	return unless $self->cget('-motionselect');
	my $list = $self->Subwidget('List');
	$list->selectionClear;
	my $i = $list->nearest($y);
	$list->selectionSet($i);
	$list->anchorSet($i);
}

sub NavDown {
	my $self = shift;
	my $l = $self->Subwidget('List');
	my ($sel) = $l->infoSelection;
	my $val = $self->cget('-values');
	my $last = @$val - 1;
	$sel ++;
	return if $sel > $last;
	$sel ++ while ($l->infoHidden($sel)) and ($sel < $last);
	unless ($sel > $last) {
		$l->selectionClear;
		$l->selectionSet($sel);
		$l->anchorSet($sel);
		$l->see($sel);
	}
}

sub NavFirst {
	my $self = shift;
	my $l = $self->Subwidget('List');
	$l->selectionClear;
	$l->selectionSet(0);
	$l->anchorSet(0);
	$l->see(0);
}

sub NavLast {
	my $self = shift;
	my $l = $self->Subwidget('List');
	my $val = $self->cget('-values');
	my $last = @$val - 1;
	$l->selectionClear;
	$l->selectionSet($last);
	$l->anchorSet($last);
	$l->see($last);
}

sub NavUp {
	my $self = shift;
	my $l = $self->Subwidget('List');
	my ($sel) = $l->infoSelection;
	$sel--;
	return if $sel < 0;
	$sel -- while ($l->infoHidden($sel)) and ($sel >= 0);
	unless ($self < 0) { 
		$l->selectionClear;
		$l->selectionSet($sel);
		$l->anchorSet($sel);
		$l->see($sel);
	}
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

	$self->calculateHeight;
	$self->SUPER::popUp;

	my $lb = $self->Subwidget('List');
	$lb->selectionClear;
	$lb->anchorClear;
#	$lb->selectionSet(0) if $lb->infoExists(0);
	$lb->focus unless $self->cget('-nofocus');

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
	$self->raise;
	$self->update;
}

sub Select {
	my $self = shift;

	my $list = $self->Subwidget('List');

	my ($item) = $list->infoSelection;
	if ((defined $item) and ($item ne '')) {
		$item = $list->entrycget($item, '-text');
		$self->Callback('-selectcall', $item);
	}
	$self->popDown;
}

sub values {
	my $self = shift;
	my $l = $self->Subwidget('List');
	if (@_) {
		my $new = shift;
		$l->deleteAll;
		my $count = 0;
		for (@$new) {
			$l->add($count, -text => $_);
			$count ++;
		}
	}
	my @v = $l->infoChildren('');
	my @values = ();
	for (@v) {
		push @values, $l->entrycget($_, '-text');
	}
	return \@values
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

=item L<Tk::HList>

=back

=cut

1;
__END__