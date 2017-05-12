# $Id: Chantrack.pm,v 1.13 2000-06-30 23:52:24-04 roderick Exp $
#
# Copyright (c) 1997-2000 Roderick Schertler.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Documentation is at the __END__.

# XXX
#    - disconnect doesn't run when changing servers, hook a connection
#      message additionally?
#    - track voice status
#    - sirc still outputs a message for users not on irc (code 401)

use strict;

package Sirc::Chantrack;

use Sirc::LckHash ();
use Sirc::Util qw(add_hook_type addhook arg_count_error eval_verbose ieq
		    plausible_nick run_hook sl tell_error tell_question
		    xtell);
use Exporter ();

use vars qw($VERSION @ISA @EXPORT_OK
	    %Channel %Chan_limit %Chan_op %Chan_user %Chan_voice
	    %Nick @Pend_userhost %User_chan %Userhost $Debug $Pkg);

$VERSION  = do{my@r=q$Revision: 1.13 $=~/\d+/g;sprintf '%d.'.'%03d'x$#r,@r};
$VERSION .= '-l' if q$Locker:  $ =~ /: \S/;

@ISA		= qw(Exporter);
@EXPORT_OK	= qw(%Channel %Chan_limit %Chan_op %Chan_user %Chan_voice
			%Nick %User_chan chantrack_check chantrack_show);

$Debug		= 0;
$Pkg		= __PACKAGE__;

tie %Channel	=> 'Sirc::LckHash';
tie %Chan_limit	=> 'Sirc::LckHash';
tie %Chan_op	=> 'Sirc::LckHash';
tie %Chan_user	=> 'Sirc::LckHash';
tie %Chan_voice	=> 'Sirc::LckHash';
tie %Nick	=> 'Sirc::LckHash';
tie %Userhost	=> 'Sirc::LckHash';
tie %User_chan	=> 'Sirc::LckHash';

add_hook_type '+op';
add_hook_type '-op';
add_hook_type '+voice';
add_hook_type '-voice';
add_hook_type 'drop-user';
add_hook_type 'limit';

my $Old_w;
BEGIN { $Old_w = $^W; $^W = 1 }
{ my @dummy = ($::user, $::host) }

sub debug {
    xtell "debug " . join '', @_
	if $Debug;
}

sub userhost_split {
    unless (@_ == 1) {
	arg_count_error undef, 1, @_;
	return ();
    }
    return $_[0] =~ /^(.*?)\@(.*)/s ? ($1, $2) : ();
}

sub add_user_channel {
    unless (@_ == 4) {
	arg_count_error undef, 4, @_;
	return;
    }
    my ($reason, $n, $c, $uh) = @_;

    debug "$reason add $n to $c uh $uh";
    if (ieq $n, $::nick) {
	$Channel{$c} = 1;
	$Chan_limit{$c} = $::limit{lc $c}
	    if exists $::limit{lc $c};
	tie %{ $Chan_user{$c} }, 'Sirc::LckHash';
	tie %{ $Chan_op{$c} }, 'Sirc::LckHash';
	tie %{ $Chan_voice{$c} }, 'Sirc::LckHash';
    }
    if (!exists $Nick{$n}) {
	$Nick{$n} = $n;
	tie %{ $User_chan{$n} }, 'Sirc::LckHash';
    }
    $Userhost{$n} = [userhost_split $uh]
	if defined $uh;
    $Chan_user{$c}{$n} = 1;

    $User_chan{$n}{$c} = 1;
}

sub drop_user {
    unless (@_ == 2) {
	arg_count_error undef, 2, @_;
	return;
    }
    my ($reason, $n) = @_;

    if (ieq $n, $::nick) {
	debug "$reason drop everything";
	%Channel = %Chan_limit = %Chan_user = %Chan_op = %Chan_voice
	    = %Nick = %Userhost = %User_chan = ();
    }
    else {
	debug "$reason drop $n";
	my @c = keys %{ $User_chan{$n} };
	run_hook 'drop-user', $n, @c;
	for my $c (@c) {
	    delete $Chan_user{$c}{$n};
	    delete $Chan_op{$c}{$n};
	    delete $Chan_voice{$c}{$n};
	}
	delete $Nick{$n};
	delete $Userhost{$n};
	delete $User_chan{$n};
    }
}

sub drop_user_channel {
    unless (@_ == 3) {
	arg_count_error undef, 3, @_;
	return;
    }
    my ($reason, $n, $c) = @_;

    delete $Chan_user{$c}{$n};
    delete $Chan_op{$c}{$n};
    delete $Chan_voice{$c}{$n};
    delete $User_chan{$n}{$c};
    # XXX bug, scalar tied hash is always 0
    if (!keys %{ $User_chan{$n} }) {
	# That's the only channel this user was on, drop her entirely.
	debug "$reason drop $n from $c";
	delete $Nick{$n};
	delete $Userhost{$n};
	delete $User_chan{$n};
    }
    else {
	debug "$reason drop $n from $c (partial)";
    }

    if (ieq $n, $::nick) {
	debug "$reason drop channel $c";
	for my $tn (keys %{ $Chan_user{$c} }) {
	    drop_user_channel("self-$reason", $tn, $c);
	}
	delete $Channel{$c};
	delete $Chan_limit{$c};
	delete $Chan_user{$c};
	delete $Chan_op{$c};
	delete $Chan_voice{$c};
    }
}

sub main::hook_chantrack_join {
    my ($c) = @_;
    my $uh = "$::user\@$::host";
    add_user_channel 'join', $::who, $c, $uh;
}
addhook 'join', 'chantrack_join';

sub main::hook_chantrack_leave {
    my ($c) = @_;
    drop_user_channel 'leave', $::who, $c;
}
addhook 'leave', 'chantrack_leave';

sub main::hook_chantrack_kick {
    my ($n, $c) = @_;
    drop_user_channel 'kick', $n, $c;
}
addhook 'kick', 'chantrack_kick';

sub main::hook_chantrack_signoff {
    drop_user 'signoff', $::who;
}
addhook 'signoff', 'chantrack_signoff';

sub main::hook_chantrack_disconnect {
    drop_user 'disconnect', $::nick;
}
addhook 'disconnect', 'chantrack_disconnect';

sub main::hook_chantrack_nick {
    my ($new_nick) = @_;
    delete $Nick{$::who};
    $Nick{$new_nick} = $new_nick;
    $Userhost{$new_nick} = delete $Userhost{$::who};
    $User_chan{$new_nick} = delete $User_chan{$::who};
    for my $c (keys %{ $User_chan{$new_nick} }) {
	debug "rename $::who -> $new_nick on $c";
	$Chan_user{$c}{$new_nick} = delete $Chan_user{$c}{$::who};
	if (exists $Chan_op{$c}{$::who}) {
	    debug "op rename $::who -> $new_nick on $c";
	    $Chan_op{$c}{$new_nick} = delete $Chan_op{$c}{$::who};
	}
	if (exists $Chan_voice{$c}{$::who}) {
	    debug "voice rename $::who -> $new_nick on $c";
	    $Chan_voice{$c}{$new_nick} = delete $Chan_voice{$c}{$::who};
	}
    }
}
addhook 'nick', 'chantrack_nick';

sub main::hook_chantrack_mode {
    my ($chan, $rest) = @_;
    my ($op, @arg) = split ' ', $rest;

    return unless $chan =~ /^[\#&]/;

    my ($char, $add);
    while ($op =~ s/^([-+])?(.)//) {
	if (defined $1) {
	    $char = $1;
	    $add = ($char eq '+');
	}
	my $type = $2;
	my $arg =
	    ($type eq 'l' && $add)
		? shift(@arg)
		: $type =~ /[bkov]/
		    ? shift(@arg)
		    : '';

	debug "mode $char$type arg $arg";

	if ($type eq 'o') {
	    if ($add && !$Chan_op{$chan}{$arg}) {
		debug "mode op add $arg on $chan";
		$Chan_op{$chan}{$arg} = 1;
		run_hook '+op', $chan, $arg;
	    }
	    elsif (!$add && $Chan_op{$chan}{$arg}) {
		debug "mode op drop $arg on $chan";
		delete $Chan_op{$chan}{$arg};
		run_hook '-op', $chan, $arg;
	    }
	}

	elsif ($type eq 'v') {
	    if ($add && !$Chan_voice{$chan}{$arg}) {
		debug "mode voice add $arg on $chan";
		$Chan_voice{$chan}{$arg} = 1;
		run_hook '+voice', $chan, $arg;
	    }
	    elsif (!$add && $Chan_voice{$chan}{$arg}) {
		debug "mode voice drop $arg on $chan";
		delete $Chan_voice{$chan}{$arg};
		run_hook '-voice', $chan, $arg;
	    }
	}

	elsif ($type eq 'l') {
	    my $old = $Chan_limit{$chan};
	    if ($add) {
		$Chan_limit{$chan} = $arg;
	    }
	    else {
		delete $Chan_limit{$chan};
	    }
	    run_hook 'limit', $chan, $old, $Chan_limit{$chan};
	}
    }
}
addhook 'mode', 'chantrack_mode';

sub main::hook_chantrack_324 {
    # You can't use getarg here or you screw the handling sirc itself does.
    my ($n, $c) = split ' ', $::args, 2;
    main::hook_chantrack_mode $c, $::args;
}
addhook '324', 'chantrack_324';

sub interpret_names_flag {
    unless (@_ == 3) {
	arg_count_error undef, 3, @_;
	return;
    }
    my ($n, $c, $flag) = @_;

    if ($flag eq '@') {
	if (!exists $Chan_op{$c}{$n}) {
	    $Chan_op{$c}{$n} = 1;
	    run_hook '+op', $c, $n;
	}
	return;
    }

    # Not an op.
    if (exists $Chan_op{$c}{$n}) {
	delete $Chan_op{$c}{$n};
	run_hook '-op', $c, $n;
    }

    if ($flag eq '+') {
	if (!exists $Chan_voice{$c}{$n}) {
	    $Chan_voice{$c}{$n} = 1;
	    run_hook '+voice', $c, $n;
	}
	return;
    }

    # No voice.
    if (exists $Chan_voice{$c}{$n}) {
	delete $Chan_voice{$c}{$n};
	run_hook '-voice', $c, $n;
    }
}

sub main::hook_chantrack_names {
    my ($rest) = @_;
    my ($x1, $x2, $chan, $list) = split ' ', $rest, 4;
    return unless $Channel{$chan};
    $list =~ s/^://;
    for my $who (split ' ', $list) {
	my $flag = ($who =~ s/^([+@])//) ? $1 : '';
	if (!exists $Chan_user{$chan}{$who}) {
	    add_user_channel 'names', $who, $chan, undef;
	}
	interpret_names_flag $who, $chan, $flag;
    }
}
addhook '353', 'chantrack_names';

BEGIN { undef &main::userhost }
sub main::userhost {
    unless (@_ == 2 || @_ == 3) {
	arg_count_error undef, '2 or 3', @_;
	return;
    }
    my ($n, $rhave, $rhavenot) = @_;
    my (@full, @missing);

    $rhavenot ||= sub { tell_question "Cannot find $::who on irc" };
    @full = ref $n ? @$n : ($n);

    # Process entries for which I already have the userhost info
    # immediately.
    for my $n (@full) {
	if (!plausible_nick $n) {
	    tell_error "Invalid nick `$n'";
	}
	elsif ($Userhost{$n}) {
	    debug "userhost already have $n";
	    local ($::who, $::user, $::host) = ($n, @{ $Userhost{$n} });
	    eval_verbose 'immediate userhost', $rhave;
	}
	else {
	    debug "userhost needs $n";
	    push @missing, $n;
	}
    }

    # Queue USERHOST commands for the rest, 5 at a time.
    while (@missing) {
	my @this = splice @missing, 0, 5;
	debug "doing userhost for @this";
	sl "USERHOST @this";
	push @Pend_userhost, [
    	    $rhave,
    	    $rhavenot,
	    { map { lc($_) => $_ } @this },
    	    [ @this ],
    	];
    }
}

sub main::hook_chantrack_userhost {
    my ($x, @repl) = split ' ', $::args;
    my (@parsed);

    # Since sirc's userhost parsing code is wrapped in the main raw_irc
    # loop the only way I can override it is by setting $::skip.
    $::skip = 1;

    # Parse the response.
    $repl[0] =~ s/^://
	if @repl;
    for (@repl) {
	next unless /^(\S+?)\*?=[+\-](.*?)\@(.*)/;
	my ($n, $u, $h) = ($1, $2, $3);
	push @parsed, [$n, $u, $h];
    }

    # Check that the request at the head of the queue matches this
    # response.  Invalid nicks will not be present in the response, so
    # just verify that nicks which are present were requested.
    unless (@Pend_userhost) {
	tell_error "USERHOST received without pending request";
	return;
    }
    for my $rparsed (@parsed) {
	my $n = $rparsed->[0];
	if (!$Pend_userhost[0][2]{lc $n}) {
	    tell_error "USERHOST mismatch, nick $n not in request "
			. "@{ $Pend_userhost[0][3] }";
	    return;
	}
    }

    # Break apart and remove the @Pend_userhost entry.
    my ($rhave, $rhavenot, $rmap, $rlist) = @{ shift @Pend_userhost };

    # Loop through the nicks present in the request, saving the data (if
    # appropriate) and calling the $rhave sub.
    foreach (@parsed) {
	my ($n, $u, $h) = @$_;
	delete $rmap->{lc $n};
	$Userhost{$n} = [$u, $h]
	    if exists $Nick{$n};
	local ($::who, $::user, $::host) = ($n, $u, $h);
	eval_verbose 'delayed userhost', $rhave;
    }

    # Run $rhavenot for nicks still left in $rmap.
    foreach (values %{ $rmap }) {
	local ($::who, $::user, $::host) = ($_);
	eval_verbose 'failed userhost', $rhavenot;
    }
}
addhook '302', 'chantrack_userhost';

sub chantrack_show {
    for my $chan (sort keys %Chan_user) {
	xtell "Channel $chan:";
	for my $user (sort keys %{ $Chan_user{$chan} }) {
	    xtell sprintf '    %-12s %s',
		    ($Chan_op{$chan}{$user} ? '@'
			: $Chan_voice{$chan}{$user} ? '+' : '') . $Nick{$user},
		    join '@', @{ $Userhost{$user} };
	}
    }
}

sub chantrack_check {
    my (@d, %d);

    @d = ();
    for (qw(Channel Chan_op Chan_user Chan_voice)) {
	push @d, [$_, join ' ', sort do { no strict 'refs'; keys %{ $_ } }];
    }
    while (@d > 1) {
	$d[0][1] eq $d[1][1]
	    or print "Channel mismatch between $d[0][0] and $d[1][0]\n";
	shift @d;
    }
    # XXX more checks

    require Data::Dumper;
    my (@n, @v);
    @n = qw(Channel Chan_limit Chan_op Chan_user Chan_voice
	    Nick Userhost User_chan);
    for (@n) {
	no strict 'refs';
	push @v, \%$_;
    }
    print Data::Dumper->Dump(\@v, [map { "r$_" } @n]);
}

BEGIN { $^W = $Old_w }

1;

__END__

=head1 NAME

Sirc::Chantrack - Track information about the channels you're on

=head1 SYNOPSIS

    $Channel{$chan}		# true if you're on $channel

    # These only work for channels you are on:
    $Chan_limit{$chan}		# channel limit, or non-existent
    $Chan_user{$chan}{$who}	# true if $who is on $channel
    $Chan_op{$chan}{$who}	# true if $who is an op on $channel
    $Chan_voice{$chan}{$who}	# true if $who has a voice op on $channel

    # These only work for nicks which are on at least one of
    # the channels you are on:
    $Nick{$nick}		# value is $nick, properly cased
    $User_chan{$nick}{$channel}	# true for all the channels you and
    	    	    	    	# $nick are both on

    # Overridden functions in main:
    main::userhost $user, $have, $have_not;
    main::userhost [@user_list], $have, $have_not;

    # Sirc::Util-style hooks:
    +op		gets ($channel, $nick), $who is originator
    -op		ditto
    +voice	gets ($channel, $nick), $who is originator
    -voice	ditto
    limit	gets ($channel, $old_limit, $new_limit), $who is originator

=head1 DESCRIPTION

This module tracks various data about the channels you are on, and the
nicks who are on them with you.  It also overrides main::userhost with
an enhanced version, and it provides hooks for when people gain and lose
ops.

Nothing is exported by default.

Most of the data is available in a series of hashes.  These hashes are
tied to a package which downcases the keys.

All of the hashes only track data about the channels you are on.

=over

=item B<$Channel{I<channel>}>

The keys of this hash are the names of the channels you're on.  Values
are always B<1>.

=item B<$Chan_user{I<channel>}{I<nick>}>

This hash of hashes tracks the users on the channels you're on.  The
values are always B<1>.

=item B<$User_chan{I<nick>}{I<channel>}>

This hash of hashes contains the same data as %Chan_user, but with the
keys stacked in the opposite order.

=item B<$Chan_op{I<channel>}{I<nick>}>

This hash of hashes only contains elements for the operators of the
given channels.  The values are always B<1>.

=item B<$Chan_voice{I<channel>}{I<nick>}>

This hash of hashes only contains elements for the people on the channel
who have voices.  Due to the way /NAMES works, though, it can lack people
who were +o when you showed up and got +v before you showed up (even if
they subsequenty lose the +o).  (It syncs from C</names> and C</mode>.)
Note that ops can speak without voices.  The values are always B<1>.

=item B<$Nick{I<nick>}>

This hash maps from any case of I<nick> to the proper case.

=item B<main::userhost I<nick-or-array-ref>, I<have-code> [, I<havenot-code>]>

This is an overridden version of B<main::userhost>.  It uses the cached
data to avoid going to the server for information.  Additionally, the
first arg can be a reference to an array of nicks to check on.  If you
query multiple users this way they're sent to the server in lots of 5.
Lastly, the two code arguments can be either strings or code refs.  The
data will be in $::who, $::user and $::host when the code runs.

Eg, here's how to run a command which uses userhost info for every user
on a channel:

    userhost [keys %{ $Chan_user{$c} }], sub {
	autoop_try $c, "$who!$user\@$host";
    };

=item B<+op>, B<-op>, B<+voice>, and B<-voice> hooks

These are B<Sirc::Util>-style hooks which are called when people gain
and lose ops and voices.  They are only called for people who are still
in the channel after the gain/loss.  That is, an operator leaving the
channel does not trigger the B<-op> hook.

The hooks are called with the channel as the first arg and the nick as
the second.  The originator is in $::who.  Eg, here's a trigger which
activates when you are given ops:

    use Sirc::Util qw(add_hook ieq);

    add_hook '+op', sub {
	my ($c, $n) = @_;
	timer 10, qq{ main::cmd_autoop "\Q$c\E" }
	    if ieq $n, $::nick;
    };

=item B<limit> hook

This is a Sirc::Util-style hook for channel limit changes.  It gets as
args the channel name, the old limit, and the new limit.  $::who contains
the originator.

=back

=head1 AVAILABILITY

Check CPAN or http://www.argon.org/~roderick/ for the latest version.

=head1 AUTHOR

Roderick Schertler <F<roderick@argon.org>>

=head1 SEE ALSO

sirc(1), perl(1), Sirc::Util(3pm).

=cut
