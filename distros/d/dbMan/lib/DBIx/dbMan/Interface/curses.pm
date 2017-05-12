package DBIx::dbMan::Interface::curses;

use strict;
use DBIx::dbMan::History;
use Curses;
use Curses::UI;
use Curses::UI::Common;
use base 'DBIx::dbMan::Interface';

our $VERSION = '0.02';

1;

sub init {
	my $obj = shift;

	$obj->SUPER::init(@_);

	$obj->{want_color} = 1;
	$obj->{want_color} = 0 if $obj->{-config}->color() =~ /^(0|no|false|off)$/;
	$obj->{want_compat} = 0;
	$obj->{want_compat} = 1 if $obj->{-config}->compat_mode() =~ /^(1|yes|true|on)$/;

	$obj->{ui} = new Curses::UI -color_support => $obj->{want_color},
		-clear_on_exit => 1, -mouse_support => 1,
		-compat => $obj->{want_compat};

	my @colors = ();
	if ($obj->{want_color}) {
		push @colors, -bg => $obj->{-config}->menu_bg if $obj->{-config}->menu_bg;
		push @colors, -fg => $obj->{-config}->menu_fg if $obj->{-config}->menu_fg;
	}
	$obj->{menu} = $obj->{ui}->add('menu', 'Menubar', -menu => [],
		-menuhandler => sub { $obj->menu_action(@_); }, @colors);

	my $sqlheight = $obj->{-config}->sql_window_height || 5;

	$obj->{sqlinput} = $obj->{ui}->add('sqlinput', 'Window',
		-border => 1, -y => -1, -height => $sqlheight);
	$obj->{area_window} = $obj->{ui}->add('area_window', 'Window',
		-border => 0, -y => 1, -padbottom => $sqlheight);

	$obj->{sqleditor} = $obj->{sqlinput}->add('editor','TextEditor',
		-vscrollbar => 1, -wrapping => 1);
	$obj->{area} = $obj->{area_window}->add('area', 'TextViewer',
		-text => '', -wrapping => 0, -vscrollbar => 1, -hscrollbar => 0);

	$obj->{ui}->set_binding(sub { $obj->{menu}->focus(); }, KEY_F(10));

	$obj->{sqleditor}->set_binding(sub { $obj->internal_loop(); }, KEY_ENTER());
	$obj->{sqleditor}->set_binding(sub { $obj->next_history(); }, KEY_DOWN());
	$obj->{sqleditor}->set_binding(sub { $obj->prev_history(); }, KEY_UP());
	$obj->{sqleditor}->set_binding(sub { $obj->completation(); }, "\cI");
	$obj->{sqleditor}->set_binding(sub { $obj->search('start'); }, "\cR");
	$obj->{sqleditor}->set_binding(sub { $obj->page_down(); }, KEY_NPAGE());
	$obj->{sqleditor}->set_binding(sub { $obj->page_up(); }, KEY_PPAGE());
	
	$obj->refresh_ui();
	
	$obj->horizontal_scrollbar(
		($obj->{-config}->horizontal_scrollbar =~ /^(yes|on|true|1|y|)$/)?1:0);

	$obj->{history}->load_and_store;
}

sub search {
	my $obj = shift;
	my $mode = shift;

	if ($mode eq 'start') {
		$obj->{default_bindings}->{escape} = $obj->{sqleditor}->{-bindings}->{CUI_ESCAPE()};
		$obj->{default_bindings}->{default} = $obj->{sqleditor}->{-bindings}->{''};
		$obj->{default_bindings}->{left} = $obj->{sqleditor}->{-bindings}->{KEY_LEFT()};
		$obj->{default_bindings}->{right} = $obj->{sqleditor}->{-bindings}->{KEY_RIGHT()};
		$obj->{default_bindings}->{to_start} = $obj->{sqleditor}->{-bindings}->{"\cA"};
		$obj->{default_bindings}->{to_end} = $obj->{sqleditor}->{-bindings}->{"\cE"};

		$obj->{sqleditor}->set_binding(sub { $obj->search('next'); }, "\cR");
		$obj->{sqleditor}->set_binding(sub { $obj->search('stop'); }, CUI_ESCAPE());
		$obj->{sqleditor}->set_binding(sub { $obj->search('search',@_); }, '');
		$obj->{sqleditor}->set_binding(sub { $obj->search('search',@_); }, KEY_BACKSPACE());
		$obj->{sqleditor}->set_binding(sub { $obj->search('stop',@_); }, KEY_LEFT());
		$obj->{sqleditor}->set_binding(sub { $obj->search('stop',@_); }, KEY_RIGHT());
		$obj->{sqleditor}->set_binding(sub { $obj->search('stop',@_); }, "\cE");
		$obj->{sqleditor}->set_binding(sub { $obj->search('stop',@_); }, "\cA");

		$obj->{search_pattern} = '';
		$obj->refresh_ui;
	} elsif ($mode eq 'next') {
		if ($obj->{search_pattern}) {
			my $line = $obj->{history}->reverse_search($obj->{search_pattern},1);
			if ($line) {
				$obj->{sqleditor}->text($line);
				$obj->{sqleditor}->{-pos} = length $1 if $line =~ /^(.*)$obj->{search_pattern}/i;
				$obj->{sqleditor}->draw();
			} else {
				$obj->{ui}->dobeep();
			}
		}
	} elsif ($mode eq 'stop') {
		my $origobj = shift; my $key = shift;

		delete $obj->{search_pattern};
		$obj->refresh_ui;

		$obj->{sqleditor}->set_binding(sub { $obj->search('start'); }, "\cR");
		$obj->{sqleditor}->{-bindings}->{CUI_ESCAPE()} = $obj->{default_bindings}->{escape} if exists $obj->{default_bindings}->{escape};
		$obj->{sqleditor}->{-bindings}->{''} = $obj->{default_bindings}->{default} if exists $obj->{default_bindings}->{default};
		$obj->{sqleditor}->{-bindings}->{KEY_LEFT()} = $obj->{default_bindings}->{left} if exists $obj->{default_bindings}->{left};
		$obj->{sqleditor}->{-bindings}->{KEY_RIGHT()} = $obj->{default_bindings}->{right} if exists $obj->{default_bindings}->{right};
		$obj->{sqleditor}->{-bindings}->{"\cE"} = $obj->{default_bindings}->{to_end} if exists $obj->{default_bindings}->{to_end};
		$obj->{sqleditor}->{-bindings}->{"\cA"} = $obj->{default_bindings}->{to_start} if exists $obj->{default_bindings}->{to_start};

		$origobj->process_bindings($key) if $key;
	} elsif ($mode eq 'search') {
		shift;  my $key = shift;

		if ($key eq KEY_BACKSPACE()) {
			if ($obj->{search_pattern}) {
				$obj->{search_pattern} =~ s/.$//;
				$key = '';
				$obj->refresh_ui;
			} else {
				$obj->{ui}->dobeep();
			}
		} else {
			my $line = $obj->{history}->reverse_search($obj->{search_pattern}.$key);
			if ($line) {
				$obj->{search_pattern} .= $key;
				$obj->refresh_ui;
				$obj->{sqleditor}->text($line);
				$obj->{sqleditor}->{-pos} = length $1 if $line =~ /^(.*)$obj->{search_pattern}/i;
				$obj->{sqleditor}->draw();
			} else {
				$obj->{ui}->dobeep();
			}
		}
	}
}

sub page_up {
	my $obj = shift;

	$obj->search('stop');
	$obj->{area}->cursor_pageup();
	$obj->{area}->draw();
}

sub page_down {
	my $obj = shift;

	$obj->search('stop');
	$obj->{area}->cursor_pagedown();
	$obj->{area}->draw();
}

sub completation {
	my $obj = shift;

	$obj->search('stop');
	my $line = $obj->current_line();
	my $text = $line;
	$text = $1 if $line =~ /(\S*)$/;
	my $start = 0;
	$start = length($line)-length($1) if $line =~ /\s+(\S*)$/;

	my @exprs = grep !/^$/,$obj->gather_complete($text,$line,$start);
	if (@exprs == 1) {
		$line = substr($line,0,$start).$exprs[0].' ';
		$obj->{sqleditor}->text($line);
		$obj->{sqleditor}->cursor_to_end();
		$obj->{sqleditor}->draw();
	} elsif (@exprs) {
		my $maxlength = 0;
		my $prefix = $exprs[0];
		for my $expr (@exprs) {
			$maxlength = length $expr if length $expr > $maxlength;
			if ($prefix) {
				my @prefix = split //,$prefix;
				my @expr = split //,$expr;
				$prefix = '';
				for (0..((@prefix < @expr)?@prefix-1:@expr-1)) {
					if ($prefix[$_] eq $expr[$_]) {
						$prefix .= $prefix[$_];
					} else {
						last;
					}
				}
			}
		}
		$maxlength += 2;
		use integer;
		my $cols = $obj->render_size / $maxlength;
		my $rows = @exprs / $cols;
		++$rows if $cols * $rows < @exprs;
		no integer;
		my @showlist = ();
		for my $col (1..$cols) {
			for my $row (1..$rows) {
				$showlist[$col][$row] = shift(@exprs)|| '';
			}
		}
		my $output = "Complete to:\n";
		for my $row (1..$rows) {
			for my $col (1..$cols) {
				$output .= sprintf "%*s",-$maxlength,$showlist[$col][$row];
			}
			$output .= "\n";
		}
		$obj->print($output);

		if ($prefix) {
			$line = substr($line,0,$start).$prefix;
			$obj->{sqleditor}->text($line);
			$obj->{sqleditor}->cursor_to_end();
			$obj->{sqleditor}->draw();
		}
	} else {
		$obj->{ui}->dobeep();
	}
}

sub next_history {
	my $obj = shift;

	$obj->search('stop');
	$obj->{sqleditor}->text($obj->{history}->next);
	$obj->{sqleditor}->cursor_to_end();
	$obj->{sqleditor}->draw();
}

sub prev_history {
	my $obj = shift;

	$obj->search('stop');
	$obj->{sqleditor}->text($obj->{history}->prev);
	$obj->{sqleditor}->cursor_to_end();
	$obj->{sqleditor}->draw();
}

sub get_command {
	my $obj = shift;

	my $what = $obj->current_line();
	if ($what) {
		$what =~ s/\n/ /gs;
		$obj->{sqleditor}->text('');
		$obj->print($obj->get_prompt.$what."\n");
		$obj->{history}->add($what);
	}
	return $what;
}

sub internal_loop {
	my $obj = shift;

	$obj->search('stop');

	my %action = ();

	my $idle;
	do {
		$idle = 0;
		%action = $obj->get_action();
		++$idle if $action{action} eq 'IDLE';
		do {
			%action = $obj->{-core}->handle_action(%action);
		} until ($action{processed});
	} until (($idle and $action{action} eq 'NONE') or $action{action} eq 'QUIT');

	$obj->nostatus;
	$obj->refresh_ui();

	die if $action{action} eq 'QUIT';
}

sub goodbye {
	my $obj = shift;

	$obj->SUPER::goodbye();
	sleep 1;
}

sub loop {
	my $obj = shift;

	$obj->{ui}->draw();

	$obj->internal_loop();

	eval {
		$obj->{ui}->mainloop();
	};
}

sub print {
	my $obj = shift;

	$obj->{area}->text($obj->{area}->get().$obj->{-lang}->str(@_));
	$obj->{area}->cursor_to_end();
	$obj->{area}->draw();
}

sub refresh_ui {
	my $obj = shift;

	my $prompt = $obj->get_prompt;  $prompt =~ s/\s$//;
	$prompt = "'reverse-i-search: $obj->{search_pattern}' ".$prompt if exists $obj->{search_pattern};
	$obj->{sqlinput}->title($prompt);
	$obj->{sqlinput}->draw();

	$obj->{sqleditor}->focus();
	$obj->{sqlinput}->focus();
}

sub can_pager {
	return 0;
}

sub clear_screen {
	my $obj = shift;

	$obj->{area}->text('');
	$obj->{area}->cursor_to_end();
	$obj->{area}->draw();
}

sub go_away {
	my $obj = shift;

	$obj->{ui}->leave_curses();
}

sub come_back {
	my $obj = shift;

	$obj->{ui}->reset_curses();
	$obj->{ui}->draw();
	$obj->refresh_ui();
}

sub menu_action {
	my $obj = shift;
	shift;	# menulistbox object - not needed
	my $action = shift;

	$action->{gui} = 1;		# we prefer gui version if exists

	$obj->add_to_actionlist($action);
	$obj->internal_loop();
}

sub ignore_trail {
	my $what = shift;
	$what =~ s/^[ *]+//;
	return $what;
}

sub create_submenu {
	my $obj = shift;
	my $menuref = shift;

	my @submenu = ();
	for (sort { (($b->{preference} || 0) <=> ($a->{preference} || 0)) ||
			(uc ignore_trail($a->{label} || '-') cmp
				uc ignore_trail($b->{label} || '-')) } @$menuref) {
		my @params = ();
		if (exists $_->{submenu}) {
			push @params, -submenu => $obj->create_submenu($_->{submenu});
		} elsif (exists $_->{action}) {
			push @params, -value => $_->{action};
		}
		if (exists $_->{separator}) {
			push @submenu, { -label => '-' };
		} else {
			push @submenu, { -label => ' '.$_->{label}, @params };
		}
	}
	my $maxlength = 0;
	for (@submenu) {
		$maxlength = length $_->{-label} if length $_->{-label} > $maxlength;
	}
	++$maxlength;
	for (@submenu) {
		$_->{-label} = '-' x $maxlength if $_->{-label} eq '-';
		$_->{-label} = $_->{-label} . (' ' x ($maxlength-length($_->{-label})));
	}

	return \@submenu;
}

sub insert_menu {
	my ($obj,$menu,$newmenu) = @_;

	for my $item (@$newmenu) {
		if (exists $item->{label}) {
			my @arr = grep { $item->{label} eq $_->{label} } @$menu;
			if (@arr) {
				for (@arr) {
					if (exists $_->{submenu}) {
						$obj->insert_menu($_->{submenu},$item->{submenu});
					} else {
						push @$menu,$item;
					}
				}
			} else {
				push @$menu,$item;
			}
		} else {
			push @$menu,$item;
		}
	}
}

sub rebuild_menu {
	my $obj = shift;

	my %menu = ();
	for my $ext (sort { $b->preference <=> $a->preference; }
			@{$obj->{-core}->{extensions}}) {
		my @submenu = $ext->menu();
		for (@submenu) {
			$_->{label} =~ s/_//g;
			my $current = $menu{$_->{label}}->{preference};
			if (exists($_->{preference}) and
				(not defined($current) or $_->{preference} > $current)) {
					$menu{$_->{label}}->{preference} = $_->{preference};
			}
			$menu{$_->{label}}->{submenu} = [] unless exists $menu{$_->{label}}->{submenu};
			$obj->insert_menu($menu{$_->{label}}->{submenu},$_->{submenu});
		}
	}

	my @menu = ();
	for my $mainitem (sort {
			(($menu{$b}->{preference} || 0) <=> ($menu{$a}->{preference} || 0)) ||
			(uc $a cmp uc $b) } keys %menu) {
		push @menu, { -label => $mainitem,
			-submenu => $obj->create_submenu($menu{$mainitem}->{submenu}) };
	}

	$obj->{menu}->{-menu} = \@menu;
	$obj->{menu}->draw();
}

sub render_size {
	my $obj = shift;

	return $obj->{area}->canvaswidth();
}

sub horizontal_scrollbar {
	my $obj = shift;
	my $onoff = shift;

	return (not $obj->{area}->{-wrapping}) unless defined $onoff;

	$obj->{area}->{-wrapping} = $onoff?0:1;
	$obj->{area}->cursor_to_end();
	$obj->{area}->draw();
}

sub get_key {
	my $obj = shift;
	my $key;
	1 while ($key = $obj->{ui}->get_key(5)) == -1;
	return $key;
}

sub macro {
	my ($obj,$text) = @_;

	$obj->search('stop');

	my $cr = 0;
	++$cr if $text =~ s/\\n$//;

	$obj->{sqleditor}->text($obj->{sqleditor}->current_line().$text);
	$obj->{sqleditor}->cursor_to_end();
	$obj->{sqleditor}->draw();

	$obj->internal_loop() if $cr;
}

sub bind_key {
	my ($obj,$key,$text) = @_;

	$obj->{sqleditor}->set_binding(sub { $obj->macro($text); }, $key);
}

sub status {
	my ($obj,$info) = @_;

	$obj->{ui}->status($info);
}

sub nostatus {
	my $obj = shift;

	$obj->{ui}->nostatus;
}

sub print_prompt {
	my $obj = shift;

	$obj->status(join '',@_);
}

sub infobox {
	my ($obj,$info) = @_;

	my $dialog = $obj->{ui}->add('infobox','Dialog::Basic',
		-message => $info, -title => 'Information');

	$dialog->getobj('message')->{-border} = 0;
	$dialog->getobj('message')->{-vscrollbar} = 0;
	$dialog->getobj('message')->{-wrapping} = 1;

	$dialog->modalfocus;

	$obj->{ui}->delete('infobox');
}

sub hello {  # splash
	my $obj = shift;

	$obj->status("This is dbMan, Version $main::DBIx::dbMan::VERSION.\nCurses Edition.");
	sleep 1;
	
	$obj->print("This is dbMan, Version $main::DBIx::dbMan::VERSION. Curses Edition.\n\n");
}

sub gui {
	return 1;
}

sub is_curses {
	return 1;
}

sub ask_value {
	my $obj = shift;
	my %params = @_;

	my $dialog = $obj->{ui}->add('dialog','Window',
		-border => 1, -ipad => 1, -centered => 1,
		-title => $params{-title} || 'Question',
		-height => 8, -width => 50);

	$dialog->add('label1', 'Label',
		-text => $params{-question} || 'Enter value',
		-x => 0, -y => 0);
	my $e_answer = $dialog->add('e_answer', 'TextEntry',
		-x => 0, -y => 1, -sbborder => 1);
	my $btns = $dialog->add('buttons', 'Buttonbox', -y => -1,
		-buttonalignment => 'right', -buttons => [ 
		{ -label => '< '.($params{-button} || 'Enter').' >', -value => 1 },
		{ -label => '< Cancel >', -value => 0 } ]);
	$btns->set_routine('press-button',
		sub { shift->parent->loose_focus(); });

	$e_answer->focus();

	$dialog->modalfocus();

	my $val = '';
	$val = $e_answer->get() if $btns->get();

	$obj->{ui}->delete('dialog');

	return $val;
}

sub trace {
	my $obj = shift;
	$obj->print('TRACE: ',@_);
}

sub current_line {
	my $obj = shift;

	return $obj->{sqleditor}->get();
}
