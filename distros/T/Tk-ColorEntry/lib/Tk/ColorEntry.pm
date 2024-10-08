package Tk::ColorEntry;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.09';
use Tk;

use base qw(Tk::Derived Tk::Frame);

Construct Tk::Widget 'ColorEntry';

require Tk::PopColor;

=head1 NAME

Tk::ColorEntry - Entry widget with a color selection facilities.

=head1 SYNOPSIS

  use Tk::ColorEntry;
  my $entry = $window->ColorEntry->pack;

=head1 DESCRIPTION

Megawidget, inherits L<Tk::Frame>
Tk::ColorEntry is an entry widget with a label packed to it's right.
The background color of the label is used as indicator for the current color.
Clicking the entry widget pops a L<Tk::ColorPop> widget.

Pressing escape causes the ColorPop to widthdraw. If a pick operation is active
cancels the pick operation instead.

=head1 OPTIONS

=over 4

=item Switch: B<-command>

Callback to be executed when a color is selected. The color is given as parameter.

=item Switch: B<-entryerrorcolor>

Default value '#FF0000' (red). Foreground color of the entry
when it's content is not a valid color.

=item Switch: B<-indborderwidth>

Default value 2. Borderwidth of the indicator label.

=item Switch: B<-indicatorwidth>

Default value 4. Width of the indicator label.

=item Switch: B<-indrelief>

Default value 'sunken'. Relief of the indicator label.

=item Switch: B<-popcolor>

Sets and returns the reference to the PopColor widget to be used.

=item Switch: B<-variable>

Reference to the variable where the current value is held.

=back

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;

	my $pop = delete $args->{'-popcolor'};
	
	$self->SUPER::Populate($args);
	
	my $entry = $self->Entry(
	)->pack(
		-side => 'left',
		-expand => 1,
		-fill => 'x',
# 		-pady => 2,
	);
	my $indicator = $self->Label->pack(
		-side => 'left',
		-fill => 'y',
		-padx => 2,
# 		-pady => 2,
	);
	$self->Advertise('Display', $indicator);
	$self->Advertise('Entry', $entry);
	$pop = $self->PopColor(
		-updatecall => sub {
			$self->put(shift);
		},
		-widget => $self,
	) unless defined $pop;

	$entry->bind('<Button-1>', [$self, 'popBlock']);
	$entry->bind('<ButtonRelease-1>', [$self, 'popFlip']);
	$entry->bind('<Return>', [$self, 'popFlip']);
	$entry->bind('<FocusOut>', [$self, 'popDown']);
	$entry->bind('<Key>', [$self, 'OnKey']);
	$entry->bind('<Escape>', [$self, 'OnEscape']);

	$self->{POPBLOCK} = 0;
	my $var = '';
	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		-command => ['CALLBACK', undef, undef, sub {}],
		-entryerrorcolor => ['PASSIVE', undef, undef, '#FF0000'],
		-entryforeground => ['PASSIVE', undef, undef, $self->Subwidget('Entry')->cget('-foreground')],
		-font => [$entry],
		-foreground => [$entry],
		-indborderwidth => [{-borderwidth => $indicator}, undef, undef, 2],
		-indicatorwidth => [{-width => $indicator}, undef, undef, 4],
		-indrelief => [{-relief => $indicator}, undef, undef, 'sunken'],
		-justify => [$entry],
		-popborderwidth => [{-borderwidth => $pop}, undef, undef, 1],
		-popcolor => ['PASSIVE', undef, undef, $pop],
		-poprelief => [{-relief => $pop}, undef, undef, 'raised'],
		-state => [$entry],
		-variable => [{-textvariable => $entry}, undef, undef, \$var],
		-width => [$entry],
		DEFAULT => [ $pop ],
	);

	$self->Delegates(
		DEFAULT => $pop,
	);
}

sub EntryUpdate {
	my $self = shift;
	my $entry = $self->Subwidget('Entry');
	my $display = $self->Subwidget('Display');
	my $val = $entry->get;
	if ($self->validate($val)) {
		$display->configure(-background => $val);
		$entry->configure(-foreground => $self->cget('-entryforeground'));
	} else {
		$display->configure(-background => $self->cget('-background'));
		$entry->configure(-foreground => $self->cget('-entryerrorcolor'));
	}
}

=item B<get>

Returns the contents of the entry widget if it is a valid color.

=cut

sub get {
	my $self = shift;
	my $color = $self->Subwidget('Entry')->get;
	return $color if $self->validate($color);
}

sub OnEscape {
	my $self = shift;
	if ($self->pickInProgress) {
		$self->pickCancel
	} else {
		my $save = delete $self->{'e_save'};
		$self->put($save) if defined $save;
		$self->popCancel;
	}
}

sub OnKey {
	my $self = shift;
	my $color = $self->Subwidget('Entry')->get;
	$self->put($color) if $self->validate($color);
	$self->EntryUpdate;
}

sub popCancel {
	my $self = shift;
	delete $self->{'e_save'};
	$self->cget('-popcolor')->popCancel;
}

sub popBlock {
	my $self = shift;
	if ($self->cget('-popcolor')->ismapped) {
		my $color = $self->Subwidget('Entry')->get;
		$self->Callback('-command', $color) if $self->validate($color);
		$self->{POPBLOCK} = 1;
		$self->after(400, sub { $self->{POPBLOCK} = 0});
	}
}

sub popDown {
	my $self = shift;
	delete $self->{'e_save'};
	my $color = $self->Subwidget('Entry')->get;
	$self->Callback('-command', $color) if $self->validate($color);
	$self->cget('-popcolor')->popDown;
}

sub popFlip {
	my $self = shift;
	if ($self->cget('-popcolor')->ismapped) {
		$self->popDown
	} else {
		$self->popUp unless $self->{POPBLOCK}
	}
}

sub popUp {
	my $self = shift;
	my $save = $self->Subwidget('Entry')->get;
	$self->{'e_save'} = $save;
	my $pop = $self->cget('-popcolor');
	$pop->configure(-widget => $self->Subwidget('Entry'));
	$pop->configure(-updatecall => ['put', $self]);
	$pop->put($save);
	
	$pop->popUp;
}

=item B<put>(I<$color>)

$color becomes the content of the entry widget.
Adjusts the sliders if $color is a valid color.

=cut;

sub put {
	my ($self, $color) = @_;
	unless (defined($color)) {
		warn "color is not defined";
		return
	}
	my $var = $self->Subwidget('Entry')->cget('-textvariable');
	$$var = $color;
	$self->EntryUpdate;
}

sub validate {
	my ($self, $val) = @_;
	my $repeat = $self->cget('-popcolor')->colordepth / 4;
	return $val =~ /^#(?:[0-9a-fA-F]{3}){$repeat}$/
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=cut

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::Poplevel>

=item L<Tk::PopColor>

=item L<Tk::ColorPicker>

=back

=cut

1;
__END__
