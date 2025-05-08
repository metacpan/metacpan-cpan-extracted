package Tk::ListBrowser::FilterEntry;

use strict;
use warnings;
use vars qw ($VERSION);
$VERSION =  0.06;

use base qw(Tk::Derived Tk::Entry);

Construct Tk::Widget 'FilterEntry';
use Tk;

sub Populate {
	my ($self,$args) = @_;
	$self->SUPER::Populate($args);
	$self->{FILTERINIT} = 0;
	$self->bind('<Button-1>', [$self, 'Button1']);
	$self->bind('<KeyRelease>', [$self, 'KeyRelease', Ev('A')]);
	$self->ConfigSpecs(
		-command => ['CALLBACK'],
		-filterdelay => ['PASSIVE', undef, undef, 300],
		-initforeground => ['PASSIVE', undef, undef, '#808080'],
		DEFAULT => [$self],
	);
	$self->after(1, sub {
		$self->{'fg_sav'} = $self->cget('-foreground');
		$self->reset;
	});
}

sub activate {
	my $self = shift;
	my $filter_id = $self->{'filter_id'};
	if (defined $filter_id) {
		$self->afterCancel($filter_id);
	}
	$filter_id = $self->after($self->cget('-filterdelay'), ['filter', $self]);
	$self->{'filter_id'} = $filter_id;
}

sub Button1 {
	my $self = shift;
	$self->icursor(0) if $self->filterinit;
	$self->focus;
}

sub filter {
	my $self= shift;
	$self->Callback('-command')
}

sub filterinit { return $_[0]->{FILTERINIT} };

sub initialize {
	my $self = shift;
	return unless $self->filterinit;
	$self->delete(0, 'end');
	my $fg = $self->{'fg_sav'};
	$self->configure(-foreground => $fg);
	$self->{FILTERINIT} = 0;
}

sub Delete {
	my $self = shift;
	$self->initialize if $self->filterinit;
	$self->SUPER::Delete(@_);
}

sub Backspace {
	my $self = shift;
	$self->initialize if $self->filterinit;
	$self->SUPER::Backspace(@_);
}

sub Insert {
	my $self = shift;
	$self->initialize if $self->filterinit;
	$self->SUPER::Insert(@_);
}

sub KeyRelease {
	my ($self, $key) = @_;
	if ($self->filterinit) {
		$self->icursor(0);
	} else {
		$self->activate if $key ne ''
	}
	$self->icursor(0);
}

sub reset {
	my $self = shift;
	$self->delete(0, 'end');
	$self->insert('end', 'Filter');
	$self->icursor(0);
	$self->configure(-foreground => $self->cget('-initforeground'));
	$self->{FILTERINIT} = 1;
}

1;
