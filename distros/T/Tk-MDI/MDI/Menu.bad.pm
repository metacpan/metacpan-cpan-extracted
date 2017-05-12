package Tk::MDI::Menu;

use strict;

sub new {
	my $self  = shift;
	my $class = ref($self) || $self;

	my $obj = bless {} => $class;

	my %args = @_;
	$obj->{PARENT}    = $args{-parent};
	$obj->{PARENTOBJ} = $args{-parentobj};
	$obj->{MW}        = $args{-mw};

	$obj->_createMenuBar;
	$obj->_populateMenuBar;
	return $obj;
}

sub _createMenuBar {
	my $obj = shift;

	if (defined (my $menu = $obj->{MW}->cget('-menu'))) {
		$obj->{MENU} = $menu;
	}
	else {
		$obj->{MENU} = $obj->{MW}->Menu(qw/-type menubar/);
		$obj->{MW}->configure(-menu => $obj->{MENU});
	}
}

sub _populateMenuBar {
	my $obj = shift;
	$obj->{CASCADEMENU} = $obj->{MW}->Menu(-tearoff => 0,
				-postcommand => sub { $obj->_menuPostCommand });

	$obj->{MENU}->add('cascade',
				-label => 'Window',
				-menu  => $obj->{CASCADEMENU},
				);


	$obj->{CASCADEMENU}->command(-label => 'Tile Horizontal', -command => [\&_tile, 'h', $obj]);
	$obj->{CASCADEMENU}->command(-label => 'Tile Vertical',   -command => [\&_tile, 'v', $obj]);
	$obj->{CASCADEMENU}->command(-label => 'Cascade',         -command => [\&_cascade,   $obj]);
	$obj->{CASCADEMENU}->command(-label => 'Iconify All',     -command => [\&_iconifyAll,   $obj]);
	$obj->{CASCADEMENU}->command(-label => 'Restore All',     -command => [\&_restoreAll,   $obj]);
	$obj->{CASCADEMENU}->separator;

	$obj->{INDEX} = 1;
}

sub _newWindow {
	$_[0]->newWindow;
}

sub _tile {
	$_[1]->{PARENTOBJ}->_tile($_[0]);
}

sub _cascade {
	$_[0]->{PARENTOBJ}->_cascade($_[0]);
}

sub _iconifyAll {
	$_[0]->{PARENTOBJ}->_iconifyAll($_[0]);
}

sub _restoreAll {
	$_[0]->{PARENTOBJ}->_restoreAll($_[0]);
}

sub _addWindowToList {
	my ($self, $childwindow) = @_;
	$self->{WINDOWREF}{$self->{INDEX} } = $childwindow;
	$self->{INDEX}++;
}

sub _deleteWindowFromList {
	my ($self, $childwindow) = @_;
	foreach my $n (sort keys %{$self->{WINDOWREF}}){
		if ($childwindow eq $self->{WINDOWREF}{$n}){
			delete $self->{WINDOWREF}{$n};
		}
	}
}

sub _callWindow
{
	# needed for closure of child window object..
	my $obj=shift;
	$obj->_menuFocus;
}

sub _menuPostCommand {
	my $obj = shift;

	my $w = $obj->{CASCADEMENU};

	$obj->{LASTCOUNT}=$w->index('end');
	$w->delete(6, $obj->{LASTCOUNT}) unless ($obj->{LASTCOUNT} < 6);
	$obj->{WINDOWCOUNT} = 0;

	# Now add the window names to the menu.
	my $i=1;
	my $child;
	foreach my $n (sort keys %{$obj->{WINDOWREF}}) {
		next unless $n;
		$child=$obj->{WINDOWREF}{$n};
		next unless $child;
		$obj->{WINDOWCOUNT}++;
		my $name;
		($child->{ISMIN})?($name='('.$child->{NAME}.')'):($name=$child->{NAME});
		$w->command(-label   => "$i. $name",
				-command => [\&_callWindow,$child] );
		$i++;
	}
}

1;
