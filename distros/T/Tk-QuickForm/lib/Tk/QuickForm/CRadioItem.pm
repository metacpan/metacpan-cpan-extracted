package Tk::QuickForm::CRadioItem;

=head1 NAME

Tk::QuickForm::CRadioItem - Array of Radiobuttons for Tk::QuickForm.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.07';

use Tk;
use base qw(Tk::Derived Tk::QuickForm::CBaseClass);
Construct Tk::Widget 'CRadioItem';

=head1 SYNOPSIS

 require Tk::QuickForm::CRadioItem;
 my $bool = $window->CRadioItem(@options)->pack;

=head1 DESCRIPTION

Inherits L<Tk::QuickForm::CBaseClass>.  Providess a row of Radiobuttons for L<Tk::QuickForm>.

You should never create an instance directly like above. This should
be handled by L<Tk::QuickForm>.

=head1 OPTIONS

All options, except I<-variable>, of L<Tk::Radiobutton> are available.

=over 4

=item Switch B<-disables>

Specify a hash with keys of possible button values pointing to a list of fields and notebook pages that should be disabled when the value is selected.

=item Switch B<-enables>

Specify a hash with keys of possible button values pointing to a list of fields and notebook pages that should be enabled when the value is selected.

=item Switch: B<-values>

The list of possible values.

=back

=cut

sub Populate {
	my ($self,$args) = @_;

	my $values = delete $args->{'-values'};
	warn "You need to set the -values option" unless defined $values;
	$self->{VALUES} = $values;

	$self->SUPER::Populate($args);

	
	$self->ConfigSpecs(
		-enables => ['PASSIVE', undef, undef, {}],
		-disables => ['PASSIVE', undef, undef, {}],
		DEFAULT => ['SELF'],
	);
}

sub createHandler {
	my ($self, $var) = @_;
	my $values = $self->{VALUES};
	for (@$values) {
		my $val = $_;
		$self->Radiobutton(
			-command => ['OnClick', $self, $val],
			-text => $val,
			-value => $val,
			-variable => $var,
		)->pack(-side => 'left', -padx => 2, -pady => 2);
	}
}

sub OnClick {
	my ($self, $val) = @_;
	
	my $ehash = $self->cget('-enables');
	my @ekeys = keys %$ehash;
	for (@ekeys) {
		my $l = $ehash->{$_};
		for (@$l) {
			$self->SetState($_, 'disabled');
		}
	}
	my $elist = $ehash->{$val};
	if (defined $elist) {
		for (@$elist) {
			$self->SetState($_, 'normal');
		}
	}

	my $dhash = $self->cget('-disables');
	my @dkeys = keys %$dhash;
	for (@dkeys) {
		my $l = $dhash->{$_};
		for (@$l) {
			$self->SetState($_, 'normal');
		}
	}
	my $dlist = $dhash->{$val};
	if (defined $dlist) {
		for (@$dlist) {
			$self->SetState($_, 'disabled');
		}
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
	warn "Found nothing to do for $item"
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::Radiobutton>

=item L<Tk::QuickForm>

=item L<Tk::QuickForm::CBaseClass>

=back

=cut

1;

__END__
