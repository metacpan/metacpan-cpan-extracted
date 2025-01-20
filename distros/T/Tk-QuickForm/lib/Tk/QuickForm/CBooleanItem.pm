package Tk::QuickForm::CBooleanItem;

=head1 NAME

Tk::QuickForm::CBooleanItem - Checkbutton widget for Tk::QuickForm.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.07';

use Tk;
use base qw(Tk::Derived Tk::QuickForm::CBaseClass);
Construct Tk::Widget 'CBooleanItem';

=head1 SYNOPSIS

 require Tk::QuickForm::CBaseooleanItem;
 my $bool = $window->CBooleanItem(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::QuickForm::CBaseClass>. Provides a Checkbutton field for L<Tk::QuickForm>.

You should never create an instance directly like above. This should
be handled by L<Tk::QuickForm>.

=head1 OPTIONS

All options, except I<-variable>, of L<Tk::Checkbutton> are available.

=over 4

=item Switch B<-disables>

Specify a list of fields and notebook pages that should be disabled when the checkbutton is on.

=item Switch B<-enables>

Specify a list of fields and notebook pages that should be enabled when the checkbutton is on.

=back

=cut

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);

	$self->ConfigSpecs(
		-enables => ['PASSIVE', undef, undef, []],
		-disables => ['PASSIVE', undef, undef, []],
		DEFAULT => [$self->Subwidget('Check')],
	);
	$self->after(200, ['OnClick', $self]);
}

sub createHandler {
	my ($self, $var) = @_;
	my $c = $self->Checkbutton(
		-command => ['OnClick', $self],
		-variable => $var,
	)->pack(-side => 'left', -padx => 2);
	$self->Advertise(Check => $c);
}

sub OnClick {
	my $self = shift;
	my $val = $self->get;
	my $onval = $self->cget('-onvalue');
	my $offval = $self->cget('-offvalue');
	my $elist = $self->cget('-enables');
	my $dlist = $self->cget('-disables');
	if (($val eq $onval) or ($val eq 1)) {
		for (@$elist) {
			$self->SetState($_, 'normal');
		}
		for (@$dlist) {
			$self->SetState($_, 'disabled');
		}
	} elsif (($val eq $offval) or ($val eq '')) {
		for (@$elist) {
			$self->SetState($_, 'disabled');
		}
		for (@$dlist) {
			$self->SetState($_, 'normal');
		}
	} else {
		warn "Illegal value $val in OnClick"
	}
}

sub SetState {
	my ($self, $item, $state) = @_;
	my $qf = $self->quickform;
	my $w = $qf->getWidget($item);
	if (defined $w) {
		$w->configure(-state => $state);
		return
	}
	my $nb = $qf->getNotebook;
	if (defined $nb) {
		my @pages = $nb->pages;
		if (grep /$item/, @pages) {
			$nb->pageconfigure($item, -state => $state);
			return
		}
	}
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::Checkbutton>

=item L<Tk::QuickForm>

=item L<Tk::QuickForm::CBaseClass>

=back

=cut

1;

__END__
