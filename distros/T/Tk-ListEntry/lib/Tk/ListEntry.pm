package Tk::ListEntry;

=head1 NAME

Tk::ListEntry - BrowseEntry like widget without button

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.05';

use Tk;
require Tk::PopList;

use base qw(Tk::Frame);
Construct Tk::Widget 'ListEntry';

=head1 SYNOPSIS

 require Tk::ListEntry;
 my $tree= $window->ListEntry(@options)->pack;

=head1 DESCRIPTION

B<Tk::ListEntry> is a variant of the B<Tk::BrowseEntry> widget except it does
not have a button. Clicking the entry will pop the list.

You can use all config options and methods of the Entry widget.

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-command>

Callback to be executed when you press the B<Return> button or select an item in the list.

=item Switch: B<-filter>

By default set to false. If you set it you can use the entry widget to filter the list.

=item Switch: B<-motionselect>

Default value 1

Selects list item when set hoovering over it.

=item Switch: B<-popdirection>

See L<Tk::Poplevel>.

=item Switch: B<-values>

See L<Tk::PopList>.

=back

=head1 ADVERTISED SUBWIDGETS

=over 4

=item B<Entry> The Entry widget.

=item B<List> The PopList widget.

=back

=cut

sub Populate {
	my ($self,$args) = @_;


	$self->SUPER::Populate($args);

	my $entry = $self->Entry->pack(-expand => 1, -fill => 'both');
	my $list = $self->PopList(
		-nofocus => 1,
		-confine => 1,
		-selectcall => ['EntrySelect', $self],
		-widget => $entry,
	);
	$list->bind('<Button-1>',[$self, 'ListClick', Ev('y')]);
	$self->Advertise(Entry => $entry);
	$self->Advertise(List => $list);
	$list->Subwidget('List')->bind('<Button-1>', [$list, 'Select']);
	$entry->bind('<Button-1>', [$list, 'popFlip']);
	$entry->bind('<Down>', [$self, 'keyDown']);
	$entry->bind('<End>', [$self, 'keyEnd']);
	$entry->bind('<Home>', [$self, 'keyHome']);
	$entry->bind('<Escape>', [$list, 'popDown']);
	$entry->bind('<FocusOut>', [$list, 'popDown']);
	$entry->bind('<KeyRelease>', [$self, 'filter']);
	$entry->bind('<Return>', [$self, 'keyReturn']);
	$entry->bind('<Up>', [$self, 'keyUp']);


	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		-command => ['CALLBACK', undef, undef, sub {}],
		-filter => ['PASSIVE', undef, undef, 0],
		-foreground => [$entry],
		-motionselect => [$list],
		-popdirection => [$list],
		-values => [$list],
		DEFAULT => [$entry],
	);
	$self->Delegates(
		DEFAULT => $entry,
	);
}

=head1 METHODS

=over 4

=cut

sub EntrySelect {
	my ($self, $select) = @_;
	my $entry = $self->Subwidget('Entry');
	if (defined $select) {
		$entry->delete(0, 'end');
		$entry->insert('end', $select);
	}
	$self->Callback('-command', $entry->get);
}

sub filter {
	my $self = shift;
	return unless $self->cget('-filter');
	my $l = $self->Subwidget('List');
	my $e = $self->Subwidget('Entry');
	$l->filter($e->get);
}

sub keyDown {
	my $self = shift;
	my $l = $self->Subwidget('List');
	my $hl = $l->Subwidget('List');
	my ($sel) = $hl->selectionGet;
	if ($l->ismapped) {
		unless (defined $sel) {
			$hl->selectionSet(0) unless defined $sel;
			$hl->anchorSet(0) unless defined $sel;
		} else {
			$l->NavDown
		}
	} else {
		$hl->anchorClear;
		$l->popUp
	}
}

sub keyEnd {
	my $self = shift;
	my $l = $self->Subwidget('List');
	my $e = $self->Subwidget('Entry');
	if ($l->ismapped) {
		$l->NavLast
	} else {
		$e->icursor('end');
	}
}

sub keyHome {
	my $self = shift;
	my $l = $self->Subwidget('List');
	my $e = $self->Subwidget('Entry');
	if ($l->ismapped) {
		$l->NavFirst
	} else {
		$e->icursor(0);
	}
}

sub keyReturn {
	my $self = shift;
	my $l = $self->Subwidget('List');
	my @sel = $l->Subwidget('List')->selectionGet;
	if (($l->ismapped) and (@sel)) {
		$l->Select
	} else {
		my $e = $self->Subwidget('Entry');
		$self->Callback('-command', $e->get);
	}

}

sub keyUp {;
	my $self = shift;
	my $l = $self->Subwidget('List');
	if ($l->ismapped) {
		$l->NavUp
	} 
}

#This method is a hack to make the ListEntry
#also work with -motionselect disabled

sub ListClick {
	my ($self, $y) = @_;
	my $list = $self->Subwidget('List')->Subwidget('List');
	my $near = $list->nearest($y);
	if ((defined $near) and (! $self->cget('-motionselect'))) {
		$list->selectionSet($near);
		my $call = $list->cget('-browsecmd');
		$call->Call;
	}
}

=item B<validate>


Returns a true if the value of the entry is in the values list.

=cut

sub validate {
	my $self = shift;
	my $txt = $self->Subwidget('Entry')->get;
	my $values = $self->cget('-values');
	return 1 if grep { $txt eq $_ } @$values;
	return 0;
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

=item L<Tk::Entry>

=item L<Tk::PopList>

=back

=cut

1;