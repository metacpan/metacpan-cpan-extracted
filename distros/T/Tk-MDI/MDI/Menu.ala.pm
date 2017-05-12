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
    } else {
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

    $obj->{CASCADEMENU}->command(-label => 'Tile Horizontally', -command => [\&_tile, 'h', $obj]);
    $obj->{CASCADEMENU}->command(-label => 'Tile Vertically',   -command => [\&_tile, 'v', $obj]);
    $obj->{CASCADEMENU}->command(-label => 'Cascade',           -command => [\&_cascade,   $obj]);
    $obj->{CASCADEMENU}->command(-label => 'Minimize All',     -command => [\&_minimizeAll,   $obj]);
    $obj->{CASCADEMENU}->command(-label => 'Restore All',     -command => [\&_restoreAll,   $obj]);
    $obj->{CASCADEMENU}->separator;

    $obj->{INDEX}          = 1;   # why do I start from 1 not 0???
    $obj->{WINDOWSLISTED}  = 0;
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

sub _minimizeAll {
    $_[0]->{PARENTOBJ}->_minimizeAll($_[0]);
}

sub _restoreAll {
    $_[0]->{PARENTOBJ}->_restoreAll($_[0]);
}

sub _addWindowToList {
    my ($obj, $ref) = @_;

    $obj->{WINDOWLIST}[$obj->{INDEX}++] = $ref;
}

sub _deleteWindowFromList {
    my ($obj, $ref) = @_;

    for my $i (1 .. $obj->{INDEX} - 1) {
	if ($obj->{WINDOWLIST}[$i] eq $ref) {
	    $obj->{WINDOWLIST}[$i] = undef;
	    last;
	}
    }
}


sub _menuPostCommand {
    my $obj = shift;

    my $w = $obj->{CASCADEMENU};

    if ($obj->{WINDOWSLISTED}) {
	# if we have any windows already in the menu .. delete them.
	# should remove the hard-coded 6 from here.
	$w->delete(6, 6 + $obj->{WINDOWSLISTED});
	$obj->{WINDOWSLISTED} = 0;
    }

    # Now add the window names to the menu.

    for my $i (1 .. $obj->{INDEX} - 1) {
	my $ref  = $obj->{WINDOWLIST}[$i];
	next unless defined $ref;

	my $name = $ref->_name;

	$name = "($name)" if $ref->_isMin;

	$obj->{WINDOWSLISTED}++;
 	$w->command(-label   => "$i. $name",
 		    -command => sub {
 			$ref->_menuFocus;
 		    });
    }
}

1;
