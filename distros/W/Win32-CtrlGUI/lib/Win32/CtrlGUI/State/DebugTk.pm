###########################################################################
# Copyright 2000, 2001, 2004 Toby Ovod-Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at toby@ovod-everett.org
##########################################################################
package Win32::CtrlGUI::State::DebugTk;

use Win32::CtrlGUI;
use Win32::CtrlGUI::State;

use Tk;
use Tk::Dialog;
use Tk::HList;
use Tk::ROText;
use Win32::API;

use strict;

our ($mw, $root_bookkeeper, $hlist, $hlist_stuff, $font, $statusarea,
     $paused, $pausebutton, $resumebutton, $debugmode);

our $VERSION = '0.32'; # VERSION from OurPkgVersion

&init;

# ABSTRACT: Tk debugger of sorts for Win32::CtrlGUI::State



sub newdo {
	my $class = shift;

	$root_bookkeeper = Win32::CtrlGUI::State::bookkeeper->new(Win32::CtrlGUI::State->new(@_));

	$Win32::CtrlGUI::State::atom::action_error_handler = sub {
		my($errormsg) = @_;
		&update_status('paused');
		$mw->deiconify;
		$mw->update;
		my $dialog = $mw->Dialog(-text => "The following exception was thrown:\n$errormsg",
														 -bitmap => 'error', -title => 'Action Error',
														 -default_button => 'OK', -buttons => [qw/OK/]
														);
		$dialog->Show();
	};

	my $old_debug_print = \&Win32::CtrlGUI::State::debug_print;
	*Win32::CtrlGUI::State::debug_print = sub {
			my $self = shift;
			my($debug_level, $text) = @_;

			&append_to_status_area($text);
		};

	foreach my $widget ($mw->children) {
		$widget->destroy;
	}

	$hlist = $mw->Scrolled('HList', -scrollbars => 'se', -drawbranch => 1, -separator => '/',
						 -indent => 15, -background => 'grey')->pack(-side => 'top', -expand => 1, -fill => 'both');
	$hlist->Subwidget('scrolled')->configure(-padx => 2, -pady => 2);


	my $exit_trigger = 0;
	$mw->protocol(WM_DELETE_WINDOW => sub {$exit_trigger = 1});

	$statusarea = $mw->Scrolled('ROText', -scrollbars => 'se', -width => 140, -height => 9, -wrap => 'none')->pack(-side => 'top', -fill => 'both');
	$mw->Button(-text => 'Exit', -command => sub {$exit_trigger = 1})->pack(-side => 'right', -padx => 5, -pady => 5);
	$resumebutton = $mw->Button(-text => 'Resume', -command => sub {&update_status('running')})->pack(-side => 'right', -padx => 5, -pady => 5);
	$pausebutton = $mw->Button(-text => 'Pause', -command => sub {&update_status('paused')})->pack(-side => 'right', -padx => 5, -pady => 5);
	&update_status('running');

	$mw->iconify;
	$mw->title("Win32::CtrlGUI::State Debugger - $0");
	$mw->update;
	Win32::API->new("user32","SetWindowPos",[qw(N N N N N N N)],'N')->Call(hex($mw->frame()),-1,0,0,0,0,3);
	$debugmode and $mw->deiconify;


	&add_state('root', $root_bookkeeper);

	my $last_sweep = Win32::GetTickCount();
	my $intvl = $root_bookkeeper->{state}->wait_intvl;
	while (1) {
		if ($last_sweep + $intvl < Win32::GetTickCount()) {
			unless ($paused) {
				if ($root_bookkeeper->bk_status eq 'pfs') {
					$root_bookkeeper->bk_set_status('pcs');
				}
				if ($root_bookkeeper->bk_status eq 'pcs') {
					$root_bookkeeper->is_recognized and $root_bookkeeper->bk_set_status('active');
				}
				if ($root_bookkeeper->bk_status eq 'active') {
					$root_bookkeeper->do_action_step;
				}
				if ($root_bookkeeper->state =~ /^done|fail$/) {
					$root_bookkeeper->{executed}++;
					$root_bookkeeper->bk_set_status('never');
					&update_status('finished');
					$debugmode or $exit_trigger = 1;
				}
				&refresh_states('root', 'active');
			}
			$last_sweep = Win32::GetTickCount();
		}

		$mw->update;
		$exit_trigger and last;
		Win32::Sleep(100);
	}

	$Win32::CtrlGUI::State::atom::action_error_handler = undef;
	*Win32::CtrlGUI::State::debug_print = $old_debug_print;
}

sub update_status {
	my($status) = @_;

	$status =~ /^running|paused|finished$/ or die "Illegal status value '$status' passed.\n";
	$paused = $status eq 'running' ? 0 : 1;
	$pausebutton->configure(-state => $status eq 'running' ? 'normal' : 'disabled');
	$resumebutton->configure(-state => $status eq 'paused' ? 'normal' : 'disabled');
	&append_to_status_area("Script $status");
}

sub append_to_status_area {
	my($text) = @_;

	$statusarea->insert('end', $text ? map {(split(/\s+/,localtime($_->[0])))[3].sprintf(".%03d", $_->[1])." $text\n"} [&finetime] : "\n");
	$statusarea->see('end');
}

sub add_state {
	my($path, $bookkeeper) = @_;

	my $text;
	if (UNIVERSAL::isa($bookkeeper->{state}, 'Win32::CtrlGUI::State::multi')) {
		($text = ref($bookkeeper->{state})) =~ s/^Win32::CtrlGUI::State:://;
	} else {
		$text = $bookkeeper->{state}->stringify;
		$text =~ s/^([^=]+) =>/$1:\t/gm;
	}

	my $widget = $hlist->ROText(-wrap => 'none', -borderwidth => 0, -background => 'grey', -height => 1, -width => 200, -tabs => ['35p']);
	$widget->tagConfigure('active', -foreground => 'red', -font => [@{$font}, 'bold']);
	$widget->tagConfigure('pcs', -foreground => 'black', -font => [@{$font}, 'bold']);
	$widget->tagConfigure('pfs', -foreground => 'black', -font => [@{$font}]);
	$widget->tagConfigure('executed', -foreground => 'dark red', -font => [@{$font}]);
	$widget->tagConfigure('skipped', -foreground => 'black', -font => [@{$font}, 'overstrike']);
	$widget->tagConfigure('default', map {@{$_}[0,4]} $widget->tagConfigure('pfs'));

	$widget->insert('end', $text, 'default');
	$widget->configure(-height => ($text =~ tr/\n//)+1);

	$hlist->add($path, -itemtype => 'window', -widget => $widget);
	$hlist_stuff->{$path} = {widget => $widget, bookkeeper => $bookkeeper};
	if (UNIVERSAL::isa($bookkeeper->{state}, 'Win32::CtrlGUI::State::multi')) {
		my $i = 0;
		foreach my $substate ($bookkeeper->{state}->get_states) {
			&add_state("$path/".$i++, $substate);
		}
	}
}

sub refresh_states {
	my($path, $pstatus) = @_;

	my $stuff = $hlist_stuff->{$path};
	my $status = $stuff->{bookkeeper}->bk_status_given($pstatus);
	if ($status ne $stuff->{old_status}) {
		if ($status eq 'active') {
			$stuff->{widget}->tagConfigure('default', map {@{$_}[0,4]} $stuff->{widget}->tagConfigure($status));
			$hlist->yview($path);
		} elsif ($status eq 'pcs' or $status eq 'pfs') {
			$stuff->{widget}->tagConfigure('default', map {@{$_}[0,4]} $stuff->{widget}->tagConfigure($status));
		} elsif ($status eq 'never') {
			if ($stuff->{bookkeeper}->{executed}) {
				$stuff->{widget}->tagConfigure('default', map {@{$_}[0,4]} $stuff->{widget}->tagConfigure('executed'));
			} else {
				$stuff->{widget}->tagConfigure('default', map {@{$_}[0,4]} $stuff->{widget}->tagConfigure('skipped'));
			}
		} else {
			die "ARGH!";
		}

		if ($stuff->{old_status} eq 'pcs' && !UNIVERSAL::isa($stuff->{bookkeeper}->{state}, 'Win32::CtrlGUI::State::multi')) {
			my $text = $stuff->{bookkeeper}->{state}->stringify;
			$text =~ s/^([^=]+) =>/$1:\t/gm;
			$stuff->{widget}->delete('1.0', 'end');
			$stuff->{widget}->insert('end', $text, 'default');
			$stuff->{widget}->configure(-height => ($text =~ tr/\n//)+1);
		}

		$stuff->{old_status} = $status;
	}

	if ($status eq 'pcs' && !UNIVERSAL::isa($stuff->{bookkeeper}->{state}, 'Win32::CtrlGUI::State::multi')) {
		my(@text) = $stuff->{bookkeeper}->{state}->tagged_stringify;
		$stuff->{widget}->delete('1.0', 'end');
		my $lines = 1;
		foreach my $i (@text) {
			$stuff->{widget}->insert('end', $i->[0], $i->[1]);
			$lines += ($i->[0] =~ tr/\n//);
		}
		$stuff->{widget}->configure(-height => $lines);
	}

	my(@children) = $hlist->info('children', $path);

	if ($status eq 'active' && scalar(grep {$hlist_stuff->{$_}->{bookkeeper}->bk_status eq 'active'} @children)) {
		$status = 'pfs';
	}

	foreach my $subpath (@children) {
		&refresh_states($subpath, $status);
	}
}

sub init {
	$mw = MainWindow->new;
	$mw->withdraw();
	$font = [qw(Arial 8)];

	my $width = $mw->screenwidth();
	my $height = $mw->screenheight();
	$mw->geometry(sprintf("%dx%d+%d+%d", $width*.4, $height-100, $width*.6-32, 0));

	$debugmode = 0;
}

{
	my $finetime_tick;
	my $finetime_time;

	sub finetime {
		unless ($finetime_tick) {
			$finetime_time = time+1;
			until ($finetime_time <= time) {
				$finetime_tick = Win32::GetTickCount();
			}
		}

		my $tick = Win32::GetTickCount();
		my($finetime, $finetick) = ($finetime_time + int(($tick-$finetime_tick)/1000), ($tick-$finetime_tick)%1000);

		$finetime = $finetime + int(($finetime-time+2_147_483_648)/4_294_967_296);

		return wantarray ? ($finetime, $finetick) : $finetime + $finetick/1000;
	}
}

1;

__END__

=head1 NAME

Win32::CtrlGUI::State::DebugTk - Tk debugger of sorts for Win32::CtrlGUI::State

=head1 VERSION

This document describes version 0.32 of
Win32::CtrlGUI::State::DebugTk, released January 10, 2015
as part of Win32-CtrlGUI version 0.32.

=head1 Rudimentary Instructions

If you want to try a cool demo, simply close all open Notepad windows and then
open a single, empty Notepad window.  Then run demotk.pl.  Resize the Tk window
that pops up so you can see stuff.  Then do the same thing, but first open
demotk.pl in Notepad and add a single carriage return to the end of the file.
Then play with fresh Notepad windows that have random text in them (the
contents will get save to C:\Temp\saved.txt, so if you have a file by that name
in existence, be careful:).

The color scheme is:
  Red and bold: active state
  Black and bold: possible next state
  Black and not-bold: possible future state (but not possible next state)
  Black and crossed out: state will never be reached
  Dark red: state has been executed

Also notice that you can pause and resume scripts.  You have to hit exit to
terminate the script, but if you don't set
C<$Win32::CtrlGUI::State::DebugTk::debugmode> to 1, it will terminate as soon
as the Win32::CtrlGUI::State stuff is finished, making it ideal for using with
production scripts.

Also, try opening the Notepad window, waiting for the script to recognize it
(state goes red), but then close it before it sends the text.  Notice that it
halts the script and alerts you.

=for Pod::Coverage
# FIXME: Should these be documented?
add_state
append_to_status_area
finetime
init
newdo
refresh_states
update_status

=head1 CONFIGURATION AND ENVIRONMENT

Win32::CtrlGUI::State::DebugTk requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Toby Ovod-Everett  S<C<< <toby AT ovod-everett.org> >>>

Win32::CtrlGUI is now maintained by
Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Win32-CtrlGUI AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Win32-CtrlGUI >>.

You can follow or contribute to Win32-CtrlGUI's development at
L<< http://github.com/madsen/win32-ctrlgui >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Toby Ovod-Everett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
