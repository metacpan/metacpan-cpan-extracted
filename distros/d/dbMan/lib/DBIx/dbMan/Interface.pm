package DBIx::dbMan::Interface;

use strict;
use DBIx::dbMan::History;

our $VERSION = '0.14';

1;

sub new {
	my $class = shift;
	my $obj = bless { @_ }, $class;
	$obj->{prompt_num} = 0;
	$obj->{actionlist} = [];
	$obj->init();
	return $obj;
}

sub init {
	my $obj = shift;
	$obj->prompt($obj->register_prompt(99999999),'SQL:');
	
	$obj->{history} = new DBIx::dbMan::History 
		-config => $obj->{-config};
}

sub print {
	my $obj = shift;
	print $obj->{-lang}->str(@_);
}

sub trace {
	my $obj = shift;
	print STDERR join '',@_;
}

sub hello {
	my $obj = shift;
	$obj->print("This is dbMan, Version $main::DBIx::dbMan::VERSION.\n\n");
}

sub goodbye {
	my $obj = shift;
	$obj->print("Bye.\n");
}

sub get_action {
	my $obj = shift;
	my %action = qw/action NONE/;

	if (@{$obj->{actionlist}}) {
		my $action = shift @{$obj->{actionlist}};
		%action = %$action;
	} else {
		my $command = $obj->get_command();
		$command =~ s/\n+$//s;

		if ($command) {
			$action{action} = 'COMMAND';
			$action{flags} = 'real';
			$action{cmd} = $command;
		} else {
			$action{action} = 'IDLE';
		}
	}

	return %action;
}

sub prompt {
	my ($obj,$num,$prompt) = @_;

	$obj->{prompt}->[$num] = $prompt;
}

sub get_prompt {
	my $obj = shift;

	my $prompt = '';
	for (sort { 
			($obj->{prompt_priority_list}->[$a] == $obj->{prompt_priority_list}->[$b])
			? ($b <=> $a)
			: ($obj->{prompt_priority_list}->[$a] <=> $obj->{prompt_priority_list}->[$b])
		} 1..$obj->{prompt_num}) {
		$prompt .= $obj->{prompt}->[$_].' ' if $obj->{prompt}->[$_];
	}
	return $prompt;
}

sub get_command {
	my $obj = shift;
	$obj->print($obj->get_prompt);
	my $command = <>;
	return $command;
}

sub error {
	my $obj = shift;
	$obj->print("ERROR: ",join '',@_,"\n");
}

sub get_password {
	my $obj = shift;
	system 'stty -echo';
	$obj->print(shift || 'Password: ');
	my $pass = <>;  $pass =~ s/\n$//;
	system 'stty echo';
	print "\n";
	return $pass;
}

sub render_size {
	my $obj = shift;
	return 79;
}

sub register_prompt {
	my ($obj,$priority) = @_;
	$priority = 0 unless $priority;
	$obj->{prompt_priority_list}->[++$obj->{prompt_num}] = $priority;
	return $obj->{prompt_num};
}

sub deregister_prompt {
	my ($obj,$prompt_id) = @_;
	return unless defined $prompt_id;
	splice @{$obj->{prompt_priority_list}},$prompt_id,1;
	splice @{$obj->{prompt}},$prompt_id,1;
	--$obj->{prompt_num};
}

sub add_to_actionlist {
	my $obj = shift;
	my $action = shift;
	push @{$obj->{actionlist}},$action;
}

sub filenames_complete {
	my $obj = shift;
	my $pattern = shift;

	my @files = (<$pattern*>);
	foreach (@files) {
	    $_ .= '/' if -d _;
	}
	return @files;
}

sub loop {
	my $obj = shift;
	my %action = ();

	do {
		%action = $obj->get_action();
		do {
			%action = $obj->{-core}->handle_action(%action);
		} until ($action{processed});
	} until ($action{action} eq 'QUIT');
}

sub history_clear {
	my $obj = shift;
	$obj->{history}->clear();
}

sub history_add {
	my $obj = shift;
	$obj->{history}->add(@_);
}

sub rebuild_menu {
	# nothing to do, special purpose for descendant
}

sub bind_key {
	# we can't do anything, it's for descendant
}

sub get_key {
	# we can't do anything, it's for descendant
}

sub can_pager {
	return 1;
}

sub clear_screen {
	my $obj = shift;

	eval {
		use Term::Screen;

		my $scr = new Term::Screen;
		die "no" unless $scr;
		$scr->clrscr();
	};
	if ($@) { # fallback
		my $oldpath = $ENV{PATH};
		$ENV{PATH} = '';
		system '/usr/bin/clear';
		$ENV{PATH} = $oldpath;
	}
}

sub go_away {

}

sub come_back {

}

sub gather_complete {
	my ($obj,$text,$line,$start) = @_;
	my %action = (action => 'LINE_COMPLETE',
		text => $text, line => $line, start => $start);
	do {
		%action = $obj->{-core}->handle_action(%action);
	} until ($action{processed});
	return @{$action{list}} if ref $action{list} eq 'ARRAY';
	return $action{list} if $action{list};
	return ();
}

sub status {

}

sub nostatus {

}

sub print_prompt {
	my $obj = shift;

	$obj->print("\n".join('',@_)."\n");
}

sub gui {
	return 0;
}

sub current_line {
	my $obj = shift;

	return '';
}

sub infobox {
	my $obj = shift;

	$obj->print( @_ );
}
