package Tk::ListEntry;

=head1 NAME

Tk::ListEntry - BrowseEntry like widget without button

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.02';

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

=item Switch: B<-motionselect>

See L<Tk::PopList>.

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
		-confine => 1,
		-selectcall => ['EntrySelect', $self],
		-widget => $entry,
	);
	$self->Advertise(Entry => $entry);
	$self->Advertise(List => $list);
	$entry->bind('<Button-1>', [$list, 'popFlip']);
	$entry->bind('<Down>', [$list, 'popUp']);
	$entry->bind('<FocusOut>', [$self, 'EntryFocusOut', Ev('d')]);
	$entry->bind('<Return>', [$self, 'EntrySelect', Ev('d')]);


	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		-command => ['CALLBACK', undef, undef, sub {}],
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

sub EntryFocusOut {
	my ($self, $detail) = @_;
	my $pl = $self->Subwidget('List');
	my $l = $pl->Subwidget('Listbox')->Subwidget('listbox');
	my $fc = $self->focusCurrent;
	unless (defined $fc) {
		$pl->popDown;
	} else {
		unless ($fc->focusCurrent eq $l) {
			$pl->popDown;
		} 
	}
}

sub EntrySelect {
	my ($self, $select) = @_;
	my $entry = $self->Subwidget('Entry');
	if (defined $select) {
		$entry->delete(0, 'end');
		$entry->insert('end', $select);
	}
	$self->Callback('-command', $entry->get);
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


