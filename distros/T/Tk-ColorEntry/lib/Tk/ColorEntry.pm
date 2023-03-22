package Tk::ColorEntry;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';
use Tk;

use base qw(Tk::Derived Tk::Frame);

Construct Tk::Widget 'ColorEntry';

require Tk::PopColor;

=head1 NAME

Tk::ColorEntry - Entry widget with a Tk::PopColor widget attached.

=head1 SYNOPSIS

  use Tk::ColorEntry;
  my $entry = $window->ColorEntry->pack;

=head1 DESCRIPTION

Megawidget, inherits L<Tk::Frame>
Tk::ColorEntry is an entry widget with a label packed to it's right.
The background color of the label is used as indicator for the current color.
Clicking the entry widget pops a L<Tk::ColorPop> widget.

Pressing escape causes the ColorPop to widthdraw, or if a pick operation is in motion
cancels the pick operation.

=head1 OPTIONS

=over 4

=item Switch: B<-entryerrorcolor>

Default value '#FF0000'. Foreground color of the entry
when it's content is not a valid color.

=item Switch: B<-indborderwidth>

Default value 2. Borderwidth of the indicator label.

=item Switch: B<-indicatorwidth>

Default value 4. Width of the indicator label.

=item Switch: B<-indrelief>

Default value 'sunken'. Relief of the indicator label.

=item Switch: B<-popborderwidth>

Default value 1. Borderwidth of the ColorPop widget.

=item Switch: B<-poprelief>

Default value 'raised'. Relief of the ColorPop widget.

=back

=cut

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);
	
	my $var = '';
	my $entry = $self->Entry(
		-textvariable => \$var,
	)->pack(
		-side => 'left', 
		-fill => 'x',
		-padx => 2,
		-pady => 2,
	);
	my $indicator = $self->Label->pack(
		-side => 'left',
		-padx => 2,
		-pady => 2,
	);
	$self->Advertise('Display', $indicator);
	$self->Advertise('Entry', $entry);
	my $pop = $self->PopColor(
		-updatecall => sub {
			$var = shift;
			$self->EntryUpdate;
		},
		-widget => $self,
	);
	$self->Advertise('Pop', $pop);

	$entry->bind('<Button-1>', [$self, 'popFlip']);
	$entry->bind('<Return>', [$self, 'popFlip']);
	$entry->bind('<FocusOut>', [$self, 'popDown']);
	$entry->bind('<Key>', [$self, 'OnKey']);
	$entry->bind('<Escape>', [$self, 'OnEscape']);

	$self->ConfigSpecs(
		-entryerrorcolor => ['PASSIVE', undef, undef, '#FF0000'],
		-entryforeground => ['PASSIVE', undef, undef, $self->Subwidget('Entry')->cget('-foreground')],
		-indborderwidth => [{
			-borderwidth => $indicator,
			-indborderwidth => $pop,
		}, undef, undef, 2],
		-indicatorwidth => [{
			-width => $indicator,
			-indicatorwidth => $pop,
		}, undef, undef, 4],
		-indrelief => [{
			-relief => $indicator,
			-indrelief => $pop,
		}, undef, undef, 'sunken'],
		-popborderwidth => [{-borderwidth => $pop}, undef, undef, 1],
		-poprelief => [{-relief => $pop}, undef, undef, 'raised'],
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

sub OnEscape {
	my $self = shift;
	if ($self->pickInProgress) {
		$self->pickCancel
	} else {
		my $save = delete $self->{'e_save'};
		$self->popDown;
		$self->put($save) if defined $save;
	}
}

sub OnKey {
	my $self = shift;
	my $color = $self->Subwidget('Entry')->get;
	$self->put($color) if $self->validate($color);
	$self->EntryUpdate;
}

sub popDown {
	my $self = shift;
	delete $self->{'e_save'};
	$self->Subwidget('Pop')->popDown;
}

sub popFlip {
	my $self = shift;
	if ($self->Subwidget('Pop')->ismapped) {
		$self->popDown
	} else {
		$self->popUp
	}
}

sub popUp {
	my $self = shift;
	my $save = $self->Subwidget('Entry')->get;
	$self->{'e_save'} = $save;
	$self->Subwidget('Pop')->popUp;
}

sub put {
	my ($self, $color) = @_;
	unless (defined($color)) {
		warn "color is not defined";
		return
	}
	my $var = $self->Subwidget('Entry')->cget('-textvariable');
	$$var = $color;
	$self->Subwidget('Pop')->put($color);
	$self->EntryUpdate;
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

=over 4

=item Hans Jeuken (hanje at cpan dot org)

=back

=cut

=head1 BUGS

Unknown. If you find any, please contact the author.

=cut

1;
__END__
