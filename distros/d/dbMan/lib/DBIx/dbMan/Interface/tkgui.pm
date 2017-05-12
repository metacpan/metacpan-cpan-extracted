package DBIx::dbMan::Interface::tkgui;

use strict;
use DBIx::dbMan::History;
use Tk;
use base 'DBIx::dbMan::Interface';

require Tk::ROText;

our $VERSION = '0.04';

1;

sub init {
	my $obj = shift;

	$obj->SUPER::init(@_);
	
	$obj->{sql} = '';

	$obj->{mw} = new MainWindow;
	$obj->{mw}->title('dbMan');
	$obj->{mw}->appname('dbMan');
	$obj->{mw}->client('dbMan');

	$obj->{menubar} = $obj->{mw}->Frame(-borderwidth => 2, -relief => 'raised')
		->pack(-side => 'top', -fill => 'x');
	$obj->{consoleframe} = $obj->{mw}->Frame(-borderwidth => 2, -relief => 'raised')
		->pack(-side => 'top', -fill => 'both', -expand => 1);
	$obj->{cmdlineframe} = $obj->{mw}->Frame->pack(-side => 'bottom', -fill => 'x');
	$obj->{promptlabel} = $obj->{cmdlineframe}->Label(-text => $obj->{-lang}->str($obj->get_prompt()),
		 -justify => 'left')->pack(-side => 'left');
	$obj->{dobutton} = $obj->{cmdlineframe}->Button(-default => 'active', -text => 'Do',
		-command => sub { $obj->handle_do; })->pack(-side => 'right');
	$obj->{cmdline} = $obj->{cmdlineframe}->Entry(-textvariable => \$obj->{sql})
		->pack(-side => 'bottom', -fill => 'x', -expand => 1);
	$obj->{cmdline}->bind('<KeyPress-Return>',sub { $obj->handle_do; });
	$obj->{cmdline}->bind('<KeyPress-Up>',sub { $obj->prev_history; });
	$obj->{cmdline}->bind('<KeyPress-Down>',sub { $obj->next_history; });
	$obj->{console} = $obj->{consoleframe}->Scrolled('ROText', -scrollbars => 'sre',
		-wrap => 'none')->pack(-fill => 'both', -expand => 1);

	$obj->{history}->load_and_store;
=comment
	$readline'rl_completion_function = sub { 
		my ($text,$line,$start) = @_;
		my %action = (action => 'LINE_COMPLETE',
			text => $text, line => $line, start => $start);
		do {
			%action = $obj->{-core}->handle_action(%action);
		} until ($action{processed});
		return @{$action{list}} if ref $action{list} eq 'ARRAY';
		return $action{list} if $action{list};
		return ();
	};
=cut
}

sub prev_history {
	my $obj = shift;
	my $hist = $obj->{history}->prev;
	print $hist."\n";
	# NOT IMPLEMENTED YET
}

sub next_history {
	my $obj = shift;
	my $hist = $obj->{history}->next;
	print $hist."\n";
	# NOT IMPLEMENTED YET
}

sub handle_do {
	my $obj = shift;
	
	my %action = ();

	do {
		%action = $obj->get_action();
		do {
			%action = $obj->{-core}->handle_action(%action);
		} until ($action{processed});
		exit if $action{action} eq 'QUIT';
	} until ($action{action} ne 'IDLE');
}

sub loop {
	my $obj = shift;

	$obj->{cmdline}->focus;

	Tk::MainLoop();
}

sub get_command {
	my $obj = shift;

	my $cmd = $obj->{sql};
	if ($cmd) {
		$obj->{sql} = '';
		$obj->{history}->add($cmd);
	}

	return $cmd;
}

sub print {
	my $obj = shift;
	$obj->{console}->insert('end',join '',$obj->{-lang}->str(@_));
	$obj->{console}->see('end');
}

sub render_size {
	my $obj = shift;
	return 80;
}

sub prompt {
	my $obj = shift;
	$obj->SUPER::prompt(@_);
	$obj->{promptlabel}->configure(-text => $obj->{-lang}->str($obj->get_prompt())) if defined $obj->{promptlabel};
}

sub can_pager {
	return 0;
}

# what is needed in this tkgui ?
# ... registering/unregistering menu items
# ... starting handle event from menu items and other actions (bind etc.)
# ... autocompletation
# ... dynamic render_size
# ... single/multiline command line
