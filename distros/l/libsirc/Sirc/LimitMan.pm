# $Id: LimitMan.pm,v 1.6 2000-07-27 12:04:46-04 roderick Exp $
#
# Copyright (c) 2000 Roderick Schertler.  All rights reserved.  This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# Documentation is at the __END__.

use strict;

package Sirc::LimitMan;

use Sirc::Chantrack	qw(%Chan_limit %Chan_user);
use Sirc::LckHash	();
use Sirc::Util		qw(addcmd add_hook arg_count_error by_server deltimer
			    have_ops_q ieq newtimer optional_channel
			    settable_boolean settable_int sl
			    tell_error tell_question timer
			    xtell);

use vars qw($VERSION);

$VERSION  = do{my@r=q$Revision: 1.6 $=~/\d+/g;sprintf '%d.'.'%03d'x$#r,@r};
$VERSION .= '-l' if q$Locker:  $ =~ /: \S/;

# These variables are tied to /set options.  XXX Allow setting these
# per-channel.
my $Enabled	= 1;		# no limit management done if false
my $Tween	= 60;		# secs between checks
my $Skew	= $Tween / 2;	# random skew if not master
my $Skew_offset	= $Skew / 2;	# constant added to skew
my $Debug	= 0;

my $N_low	= 2;
my $N_high	= 5;
my $N_reset	= $N_high - 1;

settable_boolean 'limitman', \$Enabled;
settable_int 'limitman_tween',	\$Tween,	sub { $_[1] > 0 };
settable_int 'limitman_skew',	\$Skew,		sub { $_[1] > 0 };
settable_int 'limitman_skew_offset', \$Skew_offset, sub { $_[1] > 0 };
settable_int 'limitman_low',	\$N_low,	sub { $_[1] > 0 };
settable_int 'limitman_high',	\$N_high,	sub { $_[1] > 0 };
settable_int 'limitman_reset',	\$N_reset,	sub { $_[1] > 0 };

settable_boolean 'limitman_debug', \$Debug;

# Keys are channels I'm doing limit management for, values are lists:
#
#    0 timer
#    1 true if I'm the master

sub F_TIMER	() { 0 }
sub F_AM_MASTER	() { 1 }

sub TIMER_NOW	() { 0 }
sub TIMER_MASTER () { 1 }
sub TIMER_SLAVE	() { 2 }

my %Limitman;
tie %Limitman, 'Sirc::LckHash';

sub debug {
    xtell 'limitman debug ' . join '', @_
	if $Debug;
}

# So I can examine the value.

sub debug_fetch {
    return \%Limitman;
}

sub am_master {
    my ($c) = @_;
    return $Limitman{$c} && $Limitman{$c}[F_AM_MASTER];
}

sub set_timer {
    unless (@_ == 2) {
	arg_count_error undef, 2, @_;
	return;
    }
    my ($c, $type) = @_;
    my ($delay);

    if ($type == TIMER_NOW) {
	$delay = 3;
    }
    elsif ($type == TIMER_MASTER) {
	$delay = $Tween;
    }
    elsif ($type == TIMER_SLAVE) {
	$delay = $Tween + $Skew_offset + 1 + int rand $Skew;
    }
    else {
	tell_error "set_timer called with invalid timer type $type";
	return;
    }

    debug "setting timer for $c type $type at now + $delay";
    timer $delay, sub { limitman_do($c) }, $Limitman{$c}[F_TIMER] ||= newtimer;
}

sub limitman_do {
    my ($c) = @_;

    my $set	= 0;
    my $limit	= $Chan_limit{$c};
    my $users	= keys %{ $Chan_user{$c} };

    if (!$Enabled) {
	debug "not enabled";
    }
    elsif (!$Limitman{$c}) {
	tell_error "limitman_do called for $c even though disabled";
	# Don't set the timer again.
	return;
    }
    elsif (!have_ops_q $c) {
	debug "$c not opped";
    }
    elsif (!defined $limit) {
	debug "$c no current limit";
	$set = 1;
    }
    else {
    	my $room = $limit - $users;
	debug "$c limit $limit users $users room $room low $N_low high $N_high";
	$set = 1 if $room < $N_low || $room > $N_high;
    }

    if ($set) {
	my $new = $users + $N_reset;
	debug "new limit on $c is $new";
	sl "MODE $c +l $new";
	$Limitman{$c}[F_AM_MASTER] = 1;
    }

    # Use the standard delay here, even for slaves.  The slaves only
    # pick a new random time when they see a master change the limit, so
    # that they stay at a certain offset from the master (so they don't
    # creep around and take over inadvertently).
    set_timer $c, TIMER_MASTER;
}

# Hook called when somebody changes the limit.

sub limit_change {
    my ($c, $old, $new) = @_;

    return if !$Limitman{$c};
    return if ieq $::who, $::nick;

    debug "limit change on $c, $old => $new";
    if (by_server) {
	if (am_master $c) {
	    debug "resetting after limit change made by server";
	    set_timer $c, TIMER_NOW;
	}
	else {
	    debug "ignoring server change, I'm not master";
	}
    }
    else {
	# Somebody else changed it.  Let them be the master.
	if (am_master $c) {
	    debug "abdicating master position";
	    $Limitman{$c}[F_AM_MASTER] = 0;
	}
	# Regardless of whether I was the master, re-start my timer to
	# sync to the new master.
	set_timer $c, TIMER_SLAVE;
    }
}
add_hook 'limit', \&limit_change;

sub main::cmd_limitman {
    optional_channel or return;

    my @a = split ' ', $::args;
    unless (@a == 1) {
	tell_question "Too many args, 0 or 1 expected";
	return;
    }

    my $c = shift @a;
    if ($Limitman{$c}) {
	xtell "Disabling limit managment on $c";
	deltimer ${ delete $Limitman{$c} }[F_TIMER];
    }
    else {
	xtell "Starting limit management on $c";
	$Limitman{$c} = [];
	limitman_do $c;
    }
}
addcmd 'limitman';

1;

__END__

=head1 NAME

Sirc::LimitMan - simple channel limit management

=head1 SYNOPSIS

    /eval use Sirc::LimitMan

    /limitman			# toggles management on current channel
    /limitman #mychan		# toggles management on #mychan

=head1 DESCRIPTION

This module provides a command which will do simple channel limit
management.  When invoked for a channel you will occasionally modify
the channel's limit to keep it within a certain distance of the actual
number of users.  The channel can become full while limit management
is in place.  This is intentional, if the limit were always upped in
order to allow somebody else to join, it would be pointless.

This code tries to keep the noise down by limiting the number of +l
changes.  A client running it considers itself the master if it's the
last one who made a change to the limit.  Normally the clients try to
schedule themselves so that only the master keeps changing the limit,
but somebody else will step in if he falls down on the job.

=head1 Settable Options

You can set these values with B<sirc>'s /set command.  Most of them
should really be specifiable per-channel, but they aren't.  Sorry.

=over 4

=item limitman B<on>|B<off>

If disabled then no limit management is done.  The channels you want
limit management for are still remembered, so if you enable it again
later they'll kick in again.  The default is B<on>.

=item limitman_debug B<on>|B<off>

Turning this on causes the module to let you in on its cogitations.  It
defaults to B<off>.

=item limitman_tween I<seconds>

This is the base number of seconds between checks to see if the limit
should be adjusted.  The default is 60.

=item limitman_skew I<seconds>

Non-masters have an additional delay between checks.  Part of it is a
random delay of up to B<limitman_skew> seconds, default 30.

=item limitman_skew_offset I<seconds>

An additional part of the delay for non-masters is a constant
B<limitman_skew_offset> seconds, default 15.

=item limitman_low I<count>

The limit will raised if there are fewer than B<limitman_low> free slots
on the channel, default 2.

=item limitman_high I<count>

The limit will lowered if there are more than B<limitman_high> free
slots on the channel, default 5.

=item limitman_reset I<count>

When the limit is reset, it's set to the current number of users plus
B<limitman_reset>, default 4.

=back

=head1 AVAILABILITY

Check CPAN or http://www.argon.org/~roderick/ for the latest version.

=head1 AUTHOR

Roderick Schertler <F<roderick@argon.org>>

=head1 SEE ALSO

sirc(1), perl(1), Sirc::Chantrack(3pm), Sirc::Util(3pm).

=cut
