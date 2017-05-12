###########################################################################
#
# Win32::CtrlGUI::State - an abstract parent class for implementing States
#
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
package Win32::CtrlGUI::State;

use strict;
use 5.006;

use Win32::CtrlGUI;

our ($wait_intvl, $action_delay, $debug);

our $VERSION = '0.32'; # VERSION from OurPkgVersion

&init;

#ABSTRACT: OO system for controlling Win32 GUI windows through a state machine


sub new {
	my $class = shift;
	my $type = shift;

	$class = "Win32::CtrlGUI::State::".$type;
	(my $temp = "$class.pm") =~ s/::/\//g;
	require $temp;
	if (scalar(@_) == 1 && ref $_[0] eq 'ARRAY') {
		return $class->_new(@{$_[0]});
	} else {
		return $class->_new(@_);
	}
}


sub _new {
	my $class = shift;

	my $self = {
		@_,
		state => 'init',
	};

	bless $self, $class;
}


sub newdo {
	my $class = shift;

	my $self = $class->new(@_);
	$self->do_state;
	return $self;
}


sub is_recognized {
	my $self = shift;

	die "Win32::CtrlGUI::State::is_recognized is an abstract method and needs to be overriden.\n";
}


sub wait_recognized {
	my $self = shift;

	$self->{state} ne 'rcog' and $self->debug_print(1, "Waiting for criteria $self->{criteria}.");
	until ($self->is_recognized) {
		Win32::Sleep($self->wait_intvl);
	}
}


sub do_action_step {
	my $self = shift;

	die "Win32::CtrlGUI::State::do_action_step is an abstract method and needs to be overriden.\n";
}


sub wait_action {
	my $self = shift;

	$self->state =~ /^actn|rcog$/ or return 0;

	while (1) {
		$self->do_action_step;
		$self->state =~ /^done|fail$/ and last;
		Win32::Sleep($self->wait_intvl);
	}
	return 1;
}


sub do_state {
	my $self = shift;

	$self->wait_recognized;
	$self->wait_action;
}


sub reset {
	my $self = shift;

	$self->{state} = 'init';
}


#### Accessor methods

sub state {
	my $self = shift;
	return $self->{state};
}

sub wait_intvl {
	my $self = shift;
	return defined $self->{wait_intvl} ? $self->{wait_intvl} : $wait_intvl;
}

sub action_delay {
	my $self = shift;
	return defined $self->{action_delay} ? $self->{action_delay} : $action_delay;
}

sub criteria {
	my $self = shift;
	return $self->{criteria};
}

#### Generic Debug Code

sub debug {
	my $self = shift;
	return defined $self->{debug} ? $self->{debug} : $debug;
}

sub debug_print {
	my $self = shift;
	my($debug_level, $text) = @_;

	if ($debug_level & $self->debug) {
		print $text,"\n";
	}
}

#### Class Methods

sub init {
	$wait_intvl = 100;
	$action_delay = 5;
	$debug = 0;
}


###########################################################################
# Win32::CtrlGUI::State::atom
###########################################################################

package Win32::CtrlGUI::State::atom;
@Win32::CtrlGUI::State::atom::ISA = ('Win32::CtrlGUI::State');
our ($action_error_handler);

sub _new {
	my $class = shift;

	my $self = $class->SUPER::_new(@_);

	if (ref ($self->{criteria}) eq 'ARRAY') {
		$self->{criteria} = Win32::CtrlGUI::Criteria->new(@{$self->{criteria}});
	}

	return $self;
}

sub is_recognized {
	my $self = shift;

	if ($self->state =~ /^init|srch$/) {
		if ($self->state eq 'init') {
			$self->{state} = 'srch';
			$self->{timeout} and $self->{end_time} = Win32::GetTickCount()+$self->{timeout}*1000;
		}
		my $rcog = $self->{criteria}->is_recognized;
		if ($rcog) {
			if (ref $rcog) {
				$self->{rcog_win} = $rcog;
				$self->{name} and $Win32::CtrlGUI::Window::named_windows{$self->{name}} = $rcog;
			}

			$self->{state} = 'rcog';
			$self->{rcog_time} = Win32::GetTickCount();
			$self->debug_print(1, "Criteria $self->{criteria} met.");
		} else {
			if ($self->{end_time} && $self->{end_time} < Win32::GetTickCount()) {
				$self->debug_print(1, "Criteria $self->{criteria} was timed out.");
				$self->{state} = 'fail';
				return 1;
			}
			return 0;
		}
	} else {
		return 1;
	}
}

sub do_action_step {
	my $self = shift;

	if ($self->state eq 'rcog') {
		$self->{state} = 'actn';
		my $wait_time = $self->{rcog_time}/1000 + $self->action_delay - Win32::GetTickCount()/1000;
		$wait_time > 0 and $self->debug_print(1, sprintf("Looping for %0.3f seconds before executing action.", $wait_time));
	}
	$self->state eq 'actn' or return;

	if ($self->{rcog_time} + $self->action_delay * 1000 <= Win32::GetTickCount()) {
		my $coderef;
		if (ref $self->{action} eq 'CODE') {
			$self->debug_print(1, "Executing code action.");
			$coderef = $self->{action};
		} elsif ($self->{action}) {
			$self->debug_print(1, "Sending keys '$self->{action}'.");
			$coderef = sub { $_[0]->{rcog_win}->send_keys($_[0]->{action}); };
		} else {
			$self->debug_print(1, "No action.");
			$coderef = sub {};
		}

		eval {$coderef->($self);};
		if ($@) {
			$self->action_error_handler->($@);
		}

		$self->debug_print(1, "");
		$self->{state} = 'done';
	}
}

sub wait_action {
	my $self = shift;

	$self->state =~ /^actn|rcog$/ or return 0;

	my $wait_time = $self->{rcog_time} + $self->action_delay * 1000 - Win32::GetTickCount();
	if ($wait_time > 0) {
		$self->debug_print(1, "Sleeping for ".($wait_time/1000)." seconds before executing action.");
		Win32::Sleep($wait_time);
	}

	return $self->SUPER::wait_action();
}

sub reset {
	my $self = shift;

	$self->SUPER::reset;

	delete($self->{rcog_time});
	delete($self->{rcog_win});
	delete($self->{end_time});
	UNIVERSAL::isa($self->{criteria}, 'Win32::CtrlGUI::Criteria') and $self->{criteria}->reset;
}

sub action_error_handler {
	my $self = shift;

	ref($self->{action_error_handler}) eq 'CODE' and return $self->{action_error_handler};
	ref($action_error_handler) eq 'CODE' and return $action_error_handler;
	return sub { die $_[0]; };
}

sub stringify {
	my $self = shift;

	return join("\n", map {"$_ =>$self->{$_}"} grep {exists $self->{$_}} qw(criteria action name timeout));
}

sub tagged_stringify {
	my $self = shift;

	my @retval;

	push(@retval, ["criteria:\t", 'default']);
	push(@retval, $self->{criteria}->tagged_stringify);
	push(@retval, ["\n", 'default']);

	foreach my $i (qw(action name)) {
		exists $self->{$i} or next;
		push(@retval, ["$i:\t$self->{$i}\n", 'default']);
	}

	if ($self->{timeout}) {
		my $timeout;
		if ($self->{end_time}) {
			$timeout = ($self->{end_time}-Win32::GetTickCount())/1000;
			$timeout < 0 and $timeout = 0;
			$timeout = sprintf("%0.3f", $timeout);
		} else {
			$timeout = 'wait';
		}
		push(@retval, ["timeout => $timeout\n", 'default']);
	}

	chomp($retval[$#retval]->[0]);

	return @retval;
}



###########################################################################
# Win32::CtrlGUI::State::multi
###########################################################################

package Win32::CtrlGUI::State::multi;
@Win32::CtrlGUI::State::multi::ISA = ('Win32::CtrlGUI::State');

sub _new {
	my $class = shift;

	$class eq 'Win32::CtrlGUI::State::multi' and die "$class is an abstract parent class.\n";

	my $self = {
		states => [],
		state => 'init',
	};

	bless $self, $class;

	while (my $i = shift) {
		if (ref $i eq 'ARRAY') {
			push(@{$self->{states}}, Win32::CtrlGUI::State::bookkeeper->new(Win32::CtrlGUI::State->new(@{$i})));
		} elsif (UNIVERSAL::isa($i, 'Win32::CtrlGUI::State')) {
			push(@{$self->{states}},  Win32::CtrlGUI::State::bookkeeper->new($i));
		} else {
			my $value = shift;
			if (grep {$_ eq $i} $self->_options) {
				$self->{$i} = $value;
			} else {
				ref $value eq 'ARRAY' or
						die "$class demands ARRAY refs, Win32::CtrlGUI::State objects, or class => [] pairs.\n";
				push(@{$self->{states}},  Win32::CtrlGUI::State::bookkeeper->new(Win32::CtrlGUI::State->new($i, $value)));
			}
		}
	}

	$self->{criteria} = $class;

	$self->init;

	return $self;
}

#### _options is a class method that returns a list of known "options" that the
#### class accepts - options are considered to be paired with their value.

sub _options {
	return qw();
}

#### init gets called when a multi is initialized (i.e. by new) and when it is
#### reset.  It should set the subclass statuses appropriately.

sub init {
	my $self = shift;

	die "Win32::CtrlGUI::State::multi::init is an abstract method.";
}

#### state_recognized gets called when a substate is recognized for the first
#### time.  The state will be marked as active prior to the call, which is how
#### state_recognized can find it.

sub state_recognized {
	my $self = shift;

	die "Win32::CtrlGUI::State::multi::state_recognized is an abstract method.";
}

#### state_completed gets called when a substate is recognized for the first
#### time.  The state will be marked as active prior to the call, which is how
#### state_completed can find it.

sub state_completed {
	my $self = shift;

	die "Win32::CtrlGUI::State::multi::state_completed is an abstract method.";
}

sub get_states {
	my $self = shift;
	my($status) = @_;

	if ($status) {
		my(@retstates);
		if (ref $status eq 'Regexp') {
			@retstates = grep {$_->bk_status =~ /$status/} @{$self->{states}};
		} else {
			@retstates = grep {$_->bk_status eq $status} @{$self->{states}};
		}
		if ($status eq 'active') {
			scalar(@retstates) > 1 and die "Win32::CtrlGUI::State::multi::get_active_state error: more than one state is currently active.";
			return $retstates[0];
		}
		return @retstates;
	} else {
		return @{$self->{states}};
	}
}

sub is_recognized {
	my $self = shift;

	if ($self->state =~ /^init|srch$/) {
		$self->state eq 'init' and $self->{state} = 'srch';
		my $temp = $self->_is_recognized;
		if ($temp && $self->state eq 'srch') {
			$self->{state} = 'rcog';
		}
		return $temp;
	} else {
		return 1;
	}
}

#### _is_recognized tells you whether the current state (which could be one of
#### many) is recognized

sub _is_recognized {
	my $self = shift;

	scalar($self->get_states('active')) and return 1;
	my(@pcs_states) = $self->get_states('pcs');
	if (scalar(@pcs_states)) {
		foreach my $i (@pcs_states) {
			if ($i->is_recognized) {
				$i->bk_set_status('active');
				$self->state_recognized;
				return 1;
			}
		}
		return 0;
	} else {
		if (scalar($self->get_states('pfs'))) {
			die "Win32::CtrlGUI::State::multi::_is_recognized error: there should be no pfs states if there are no pcs states.";
		} else {
			$self->{state} = 'done';
			return 0;
		}
	}
}

sub do_action_step {
	my $self = shift;

	$self->state eq 'rcog' and $self->{state} = 'actn';

	while (1) {
		$self->state eq 'actn' or return 0;

		if ($self->_is_recognized) {
			$self->get_states('active')->do_action_step;
			if ($self->get_states('active')->state =~ /^done|fail$/) {
				$self->get_states('active')->{executed}++;
				$self->get_states('active')->bk_set_status('comp');
				$self->state_completed;
				next;
			}
		}

		last;
	}
}

sub reset {
	my $self = shift;

	$self->SUPER::reset;

	foreach my $state (@{$self->{states}}) {
		$state->reset;
	}

	$self->init;
}


###########################################################################
# Win32::CtrlGUI::State::seq
###########################################################################

package Win32::CtrlGUI::State::seq;
@Win32::CtrlGUI::State::seq::ISA = ('Win32::CtrlGUI::State::multi');

sub init {
	my $self = shift;

	$self->{states}->[0]->bk_set_status('pcs');
}

sub state_recognized {
	my $self = shift;

	foreach my $i ($self->get_states) {
		$i->bk_status eq 'active' and last;
		$i->bk_set_status('never');
	}
}

sub state_completed {
	my $self = shift;

	my $trigger = 0;
	foreach my $i ($self->get_states) {
		if ($i->bk_status eq 'comp') {
			$i->bk_set_status('never');
			$trigger = 1;
			next;
		}
		if ($trigger) {
			$i->bk_set_status('pcs');
			last;
		}
		$i->bk_set_status('never');
	}
}


###########################################################################
# Win32::CtrlGUI::State::seq_opt
###########################################################################

package Win32::CtrlGUI::State::seq_opt;
@Win32::CtrlGUI::State::seq_opt::ISA = ('Win32::CtrlGUI::State::multi');

sub init {
	my $self = shift;

	foreach my $i ($self->get_states) {
		$i->bk_set_status('pcs');
	}
}

sub state_recognized {
	my $self = shift;

	foreach my $i ($self->get_states) {
		$i->bk_status eq 'active' and last;
		$i->bk_set_status('never');
	}
}

sub state_completed {
	my $self = shift;

	foreach my $i ($self->get_states) {
		if ($i->bk_status eq 'comp') {
			$i->bk_set_status('never');
			last;
		}
		$i->bk_set_status('never');
	}
}


###########################################################################
# Win32::CtrlGUI::State::dialog
###########################################################################

package Win32::CtrlGUI::State::dialog;
@Win32::CtrlGUI::State::dialog::ISA = ('Win32::CtrlGUI::State');

{
	my $dialog_name = 'dialog001';

	sub _new {
		my $class = shift;
		my %data = @_;

		$data{criteria}->[0] ne 'neg' or die "Dialogs can't have negative criteria.\n";

		$data{name} ||= $dialog_name++;

		my(@base_action_keys) = grep(!/^cnfm_/, keys %data);
		my(@cnfm_action_keys) = grep(/^cnfm_/, keys %data);

		my $pos_atom = Win32::CtrlGUI::State->new('atom', map {$_ => $data{$_}} @base_action_keys);

		my $neg_atom = Win32::CtrlGUI::State->new('atom',
				criteria => [neg => \$data{name}], action_delay => 0);

		if (scalar(@cnfm_action_keys)) {
			my $cnfm_atom = Win32::CtrlGUI::State->new('atom', map {substr($_, 5) => $data{$_}} @cnfm_action_keys);
			return Win32::CtrlGUI::State->new('seq', $pos_atom, ['seq_opt', $cnfm_atom, $neg_atom]);
		} else {
			return Win32::CtrlGUI::State->new('seq', $pos_atom, $neg_atom);
		}
	}
}


###########################################################################
# Win32::CtrlGUI::State::fork
###########################################################################

package Win32::CtrlGUI::State::fork;
@Win32::CtrlGUI::State::fork::ISA = ('Win32::CtrlGUI::State::multi');

sub init {
	my $self = shift;

	foreach my $i ($self->get_states) {
		$i->bk_set_status('pcs');
	}
}

sub state_recognized {
	my $self = shift;

	foreach my $i ($self->get_states) {
		$i->bk_status eq 'active' and next;
		$i->bk_set_status('never');
	}
}

sub state_completed {
	my $self = shift;

	foreach my $i ($self->get_states) {
		$i->bk_set_status('never');
	}
}


###########################################################################
# Win32::CtrlGUI::State::loop
###########################################################################

package Win32::CtrlGUI::State::loop;
@Win32::CtrlGUI::State::loop::ISA = ('Win32::CtrlGUI::State::multi');

sub _options {
	return qw(timeout body_req);
}

sub init {
	my $self = shift;

	my $state_count = scalar($self->get_states);

	if ($state_count != 1 && $state_count != 2) {
		die "Win32::CtrlGUI::State::loop demands a body state and, optionally, an exit state.";
	}

	if ($state_count == 1 && !$self->{timeout}) {
		die "Win32::CtrlGUI::State::loop demands either an exit state or a timeout.\n";
	}

	$self->_body->bk_set_status('pcs');
	if ($state_count == 2) {
		$self->_exit->bk_set_status($self->{body_req} ? 'pfs' : 'pcs');
	}
}

sub state_recognized {
	my $self = shift;
	if ($self->_body->bk_status eq 'active') {
	} else {
		$self->_body->bk_set_status('never');
	}
}

sub state_completed {
	my $self = shift;

	if ($self->_body->bk_status eq 'comp') {
		$self->_body->bk_set_status('pcs');
		$self->_body->reset;
		$self->_exit and $self->_exit->bk_set_status('pcs');
		$self->_set_end_time(1);
	} else {
		$self->_exit->bk_set_status('never');
	}
}

sub _body {
	my $self = shift;

	return $self->{states}->[0];
}

sub _exit {
	my $self = shift;

	return $self->{states}->[1];
}

sub _set_end_time {
	my $self = shift;
	my($force) = @_;

	if ((!$self->{end_time} || $force) && $self->{timeout}) {
		$self->{end_time} = Win32::GetTickCount()+$self->{timeout}*1000;
	}
}

sub _is_recognized {
	my $self = shift;

	$self->_set_end_time(0);

	my $retval = $self->SUPER::_is_recognized;
	$retval and return $retval;

	if ($self->{end_time} && $self->{end_time} < Win32::GetTickCount()) {
		$self->{state} = 'done';
		$self->debug_print(1, "Loop exiting due to timing out after $self->{timeout} seconds.");
		return 1;
	}
	return 0;
}





1;

__END__

=head1 NAME

Win32::CtrlGUI::State - OO system for controlling Win32 GUI windows through a state machine

=head1 VERSION

This document describes version 0.32 of
Win32::CtrlGUI::State, released January 10, 2015
as part of Win32-CtrlGUI version 0.32.

=head1 SYNOPSIS

  use Win32::CtrlGUI::State;

  Win32::CtrlGUI::State->newdo(
    seq => [
      atom => [criteria => [pos => qr/Notepad/],
               action => "!fo"],

      seq_opt => [
        seq => [
          atom => [criteria => [pos => 'Notepad', qr/^The text in the .* file has changed/i],
                   action => "!y"],

          dialog => [criteria => [pos => 'Save As'],
                     action => "!nC:\\TEMP\\Saved.txt{1}{ENTER}",
                     timeout => 5,
                     cnfm_criteria => [pos => 'Save As', qr/already exists/i],
                     cnfm_action => "!y"],
        ],

        dialog => [criteria => [pos => 'Open', 'Cancel'],
                   action => "!n{1}".Win32::GetCwd()."\\test.pl{1}{HOME}{2}{ENTER}"],
      ],

      dialog => [criteria => [pos => qr/Notepad/],
                 action => "!fx"],
    ]
  );

=head1 DESCRIPTION

C<Win32::CtrlGUI::State> is used to define a set of state, the desired response to those state,
and how those states fit together so as to make it easier to control Win32 GUI windows.  Think of
it as intelligent flow-control for Win32 GUI control.  Also, it lets you use a Tk debugger to
observe your scripts as they execute.

The system itself is object-oriented - there are a number of types of states, most of which accept
a list of other states as parameters.  If you think about it, code-blocks are objects.  So are
if-then statements.  So, rather than write my own language and parser for doing flow-control of
GUI windows, I made an OO system within Perl.  Much easier than writing a parser.

The basic state subclasses are:

=over 4

=item atom

These are used to specify single "events" in the system.  Passed to the constructor are a set of
criteria and the action to take when those criteria are met.  If that atom is currently active and
the criteria become met, the action will be executed.  It also takes on optional timeout
parameter.

=item multi

This is an abstract parent class intended to support such classes as C<seq>, C<seq_opt>, C<fork>,
and C<loop>.  The preferred syntax for passing states to C<multi> subclasses is:

  multi => [
    parameter => value,
    state1_class => [ state1 parameters ],
    state2_class => [ state2 parameters ],
  ],

Alternate legal syntaxes include:

  multi => [
    [state1_class => state1 parameters],
    Win32::CtrlGUI::State:state2_class->new(state2 parameters),
  ]

That is to say, C<multi> class objects expect their parameter array to consist of a sequence of
these four "entities" (which can be alternated as desired):

=over 4

=item *

I<parameter> => I<value> pairs

=item *

I<state_class> => I<array ref to state parameters> pairs

=item *

I<array ref to state1_class, state parameters>

=item *

I<Win32::Ctrl::GUI::State class object>

=back

=item seq

The passed states will be waited for one-by-one and the actions executed.  No state is allowed to
be skipped.

=item seq_opt

This state is similar to C<seq>, except that any state may be skipped except for the last one.
That is to say, execution will "jump" to whichever state shows up first.  Once a state has been
jumped to, the previous states will not be executed. The last state in the list is sometimes
referred to as the exit criteria.

=item fork

The first state to be met will be executed and none of the others will.  Think of it as a
select-case statement.  Of course, C<seq> and C<seq_opt> states can be passed to the C<fork>
state.

=item loop

Lets you do loops:)  Loops take two optional parameters - C<timeout> and C<body_req> and either
one or two states.  The first state is the "body" state and the second the "exit" state.  I
strongly encourage the use of the C<dialog> state when building loops (this is B<especially>
critical for loops where the body only has one state - otherwise, simple atoms may trigger
multiple times off of the same window).

=item dialog

The C<dialog> state was created to deal with a common problem, that is to say waiting for a window
to pop up, sending it text, and then waiting for it to disappear.  In addition, the C<dialog>
state takes an optional set of parameters for a "confirmation" window.  If the confirmation window
shows up before the original window disappears, the confirmation action will be executed.  The
C<dialog> state is implemented using a C<seq> state and, if there is a confirmation specification,
a C<seq_opt> state.  Note that waiting for the window to disappear is based on the window handle,
not on the criteria, which makes this safe to use in loops.

=back

Of note, if you pass a C<multi> state to another C<multi> state, remember that the "child" state
has to finish executing before the parent can continue.  For instance, in the following code, if
the window "Foo" is seen, seeing the window "Done" will not cause the loop to exit until the
window "Bar" has been seen.

  Win32::CtrlGUI::State->newdo(
    loop => [
      seq => [
          dialog => [criteria => [pos => 'Foo'], action => '{ENTER}'],
          dialog => [criteria => [pos => 'Bar'], action => '{ENTER}'],
      ],
      seq => [
          atom => [criteria => [pos => 'Done'], action => '{ENTER}'],
      ],
    ]
  );

=head1 METHODS

=head2 new

The first parameter to the C<new> method is the subclass to create - C<atom>, C<seq>, C<seq_opt>,
etc.  The C<_new> method for that class is then called and the remaining parameters passed.

=head2 _new

The default C<_new> method takes a list of hash entries, places the object in the C<init> state,
and returns the object.

=head2 newdo

This calls C<new> and then C<do_state>.  It returns the C<Win32::CtrlGUI::State> object after it
has finished executing.

=head2 is_recognized

This is a generic method and has to be overriden by the subclass.  When C<is_recognized> is
called, it should return true if this state is currently or has ever been recognized (once a path
is followed, the path needs to be followed until the end.)

=head2 wait_recognized

This will wait until a given state has been recognized.

=head2 do_action_step

Because the whole system is capable of being driven in an asynchronous manner from the very top
(which makes it possible to run the C<Win32::CtrlGUI::State> system from within Tk, for instance),
actions need to be executable in a non-blocking fashion.  The method call C<do_action_step> is
crucial to that.  Remember that there is an action "delay", so C<do_action_step> will keep
returning, but not setting the state to C<done>, until that delay is used up and the action can
actually be executed.  The system does not yet allow for multi-part actions in and of themselves
(for instance, it will still block if a sendkeys action involves internal delays).

=head2 wait_action

This will wait until the action for a given state has been completed.  It should only be called
after C<is_recognized> returns true.

=head2 do_state

This will wait until the state is recognized (by calling C<wait_recognized>) and then execute the
action (by calling C<wait_action>).

=head2 reset

The reset method automagically resets the state as if nothing had ever happened.

=for Pod::Coverage
# FIXME: Should these be documented?
action_delay
criteria
debug
debug_print
state
wait_intvl

=head1 STATES

It is important to note that Win32::CtrlGUI::State objects can be in one of six different states.
They are:

=over 4

=item init

This is the state before the object has had any methods invoked on it.

=item srch

This is the state the object enters after C<is_recognized> is first called on it, but before the
desired state has been recognized.  Distinguishing between <init> and <srch> allows time outs to
be implemented.

=item rcog

This is the state the object enters after its criteria are first recognized.

=item actn

This is the state the object enters when C<do_action_step> is first called.

=item done

This is the state the object enters after the action is fully completed.

=item fail

This is the state the object enters when a time out has occurred (this doesn't apply to C<loop>
states, but does apply to C<atom> states).

=back

=head1 CONFIGURATION AND ENVIRONMENT

Win32::CtrlGUI::State requires no configuration files or environment variables.

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
