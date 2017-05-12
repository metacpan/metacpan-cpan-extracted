# $Id: Autoop.pm,v 1.11 2000-07-27 12:01:04-04 roderick Exp $
#
# Copyright (c) 1997-2000 Roderick Schertler.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

# XXX
#    - track nick changes

use strict;

package Sirc::Autoop;

use Exporter		();
use Sirc::Chantrack	qw(%Chan_op %Chan_user %Chan_voice);
use Sirc::LckHash	();
use Sirc::Util		qw(addcmd addhelp add_hook addhook ban_pattern
			    docommand doset have_ops have_ops_q ieq
			    mask_to_re notice optional_channel
			    settable_boolean settable_int tell_question
			    timer userhost xgetarg xtell);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @Autoop %Autovoice);

$VERSION  = do{my@r=q$Revision: 1.11 $=~/\d+/g;sprintf '%d.'.'%03d'x$#r,@r};
$VERSION .= '-l' if q$Locker:  $ =~ /: \S/;

@ISA		= qw(Exporter);
@EXPORT		= qw();
@EXPORT_OK	= qw(@Autoop %Autovoice);

# These variables are tied to /set options.  The *_delay options can be
# either an integer or a code ref which will compute it.  You have to
# use doset rather than /set to set them to a code ref.
my $Autoop	= 1;				# no autoops done if false
my $Autoop_delay = sub { 3 + 2 * int rand 4 };	# secs before trying to autoop
my $Autovoice	= 1;
my $Autovoice_control = 1;				# ops can control autovoice delay
my $Autovoice_delay = sub { 3 + 2 * int rand 4 };	# secs before autovoice
my $Autovoice_timeout = 60 * 60;			# secs -v is sticky
my $Debug	= 0;
my $Verbose	= 0;

settable_boolean 'autoop', \$Autoop;
settable_int 'autoop_delay', \$Autoop_delay, sub { $_[1] >= 0 };

settable_boolean 'autovoice', \$Autovoice;
settable_boolean 'autovoice_control', \$Autovoice_control;
settable_int 'autovoice_delay', \$Autovoice_delay, sub { $_[1] >= 0 };
settable_int 'autovoice_timeout', \$Autovoice_timeout, sub { $_[1] >= 0 };

settable_boolean 'autoop_debug', \$Debug;
settable_boolean 'autoop_verbose', \$Verbose;

# @Autoop is a list of array references.  The first element of each
# array is a pattern to match against the channel, the second is a
# pattern to match against the nick!user@host.  The optional third is
# either 'o' or 'v' (defaulting to 'o') to tell which mode to give.
#
# There's no user-level interface for adding data to this (yet).
@Autoop		= ();

# This is a hash whose keys are are channel names.  New keys should
# get undef as value.  Everybody joining one of the listed channels
# will get a +v after $Autovoice_delay seconds.  If somebody gets a -v
# then leaves and rejoins, though, they won't get another +v unless
# $Autovoice_timeout seconds have passed or somebody else gives them a
# +v.
#
# There's no user-level interface for adding data to this (yet).
#
# The implementation causes each value to be a hashref pointing to
# another hash.  The keys of the second level hashes are ban_pattern
# patterns converted to REs indicating the people who are in sticky -v
# mode, the value for each is the time at which it got -v.  The second
# level hash will only be present if it has keys, as the last key is
# removed the $Autovoice{$channel} entry is undeffed.
tie %Autovoice, 'Sirc::LckHash';

sub debug {
    xtell 'autoop debug ' . join '', @_
	if $Debug;
}

sub verbose {
    xtell join '', @_
	if $Verbose || $Debug;
}

sub autoop_match {
    my ($channel, $nuh) = @_;

    debug "autoop_match @_";
    for (@Autoop) {
	my ($channel_pat, $nuh_pat, $type) = @$_;

	$type = 'o' if !defined $type;
	if ($type ne 'o' && $type ne 'v') {
	    tell_question "Invalid autoop type `$type'"
    	    	    	    . " for /$channel_pat/ /$nuh_pat/";
	    next;
	}

	my $one = $channel =~ /$channel_pat/i;
	my $two = $nuh =~ /$nuh_pat/i;
	debug "channel/user $one/$two on $channel_pat/$nuh_pat";
	if ($one && $two) {
	    return $type;
	}
    }
    return 0;
}

sub sticky_devoice {
    my ($c, $n, $uh) = @_;
    my ($h, $s, $expire);

    $h = $Autovoice{$c};
    return 0 unless $h;

    $expire = time - $Autovoice_timeout;
    $s = "$n!$uh";
    for my $pat (keys %$h) {
	if ($h->{$pat} < $expire) {
	    delete $h->{$pat};
	    # undef the %Autovoice value when the last member drops.
	    if (!%$h) {
		undef $Autovoice{$c};
		return 0;
	    }
	}
	else {
	    return 1 if $s =~ /$pat/;
	}
    }
    return 0;
}

sub autoop_do {
    my ($this_channel, $this_nick, $this_userhost, $type) = @_;
    my ($mode);

    debug "autoop_do @_";

    $mode = $type;
    $mode = 'v' if $mode eq 'autovoice';

    # Don't +v or +o for ops.
    if ($Chan_op{$this_channel}{$this_nick}) {
	debug "autoop_do skip $this_channel/$this_nick/$type opped";
    }

    # Don't +v people who got it already.
    elsif ($mode eq 'v' && $Chan_voice{$this_channel}{$this_nick}) {
	debug "autoop_do skip $this_channel/$this_nick/$type voiced";
    }

    # Don't +v if we're not moderated.
    elsif ($mode eq 'v' && $::mode{lc $this_channel} !~ /m/) {
	debug "autoop_do skip $this_channel/$this_nick/$type not +m";
    }

    # Don't autovoice people who have a sticky -v.
    elsif ($type eq 'autovoice'
	    && sticky_devoice $this_channel, $this_nick, $this_userhost) {
	debug "autoop_do skip $this_channel/$this_nick/$type sticky -v";
    }

    # Don't bother if she left already
    elsif (!$Chan_user{$this_channel}{$this_nick}) {
	debug "autoop_do skip $this_channel/$this_nick/$type gone";
    }

    else {
	debug "autoop_do op $this_channel/$this_nick";
	docommand "mode $this_channel +$mode $this_nick\n";
    }
};

sub autoop_try {
    my ($this_channel, $this_nick, $this_userhost, $immediate) = @_;
    my (@base_arg);

    debug "autoop_try @_";
    have_ops $this_channel or return;
    return if ieq $this_nick, $::nick;
    @base_arg = ($this_channel, $this_nick, $this_userhost);

    if ($Autoop && (my $type = autoop_match $this_channel,
					    "$this_nick!$this_userhost")) {
	my $delay = $immediate
			? 0
			: ref($Autoop_delay) eq 'CODE'
			    ? &$Autoop_delay(@base_arg)
			    : $Autoop_delay;
	verbose "Queueing +$type for $this_nick on $this_channel in $delay"
	    if $delay > 0 || $Debug;
	timer $delay, sub { autoop_do @base_arg, $type };
    }

    if ($Autovoice && exists $Autovoice{$this_channel}) {
	my $delay = $immediate
	    	    	? 0
			: ref($Autovoice_delay) eq 'CODE'
			    ? &$Autovoice_delay(@base_arg)
			    : $Autovoice_delay;
	verbose "Queueing autovoice for $this_nick on $this_channel in $delay"
	    if $delay > 0 || $Debug;
	timer $delay, sub { autoop_do @base_arg, 'autovoice' };
    }
}

sub main::hook_autoop_join {
    my $channel = shift;
    my @arg = ($channel, $::who, "$::user\@$::host");
    autoop_try @arg, 0
	if have_ops_q $channel;
}
addhook 'join', 'autoop_join';

# When a /names list comes by, note people who don't have a voice in
# %Autovoice.  Without this I'd try to +v them when I get +o myself.
# This only has any effect when joining the channel, though it runs for
# every /names.

sub main::hook_autoop_names {
    my ($rest) = @_;
    my ($x1, $x2, $channel, $list) = split ' ', $rest, 4;

    # I used to test if the channel was +m here as well, but the on-join
    # channel mode change can come after the /names.
    return unless exists $Autovoice{$channel};

    my $now = time;
    $list =~ s/^://;
    for my $who (split ' ', $list) {
	next if $who =~ /^[+@]/;
	userhost $who, sub {
    	    my $pat = mask_to_re ban_pattern $::who, $::user, $::host;
	    $Autovoice{$channel}{$pat} ||= $now;
	};
    }
}
addhook '353', 'autoop_names';

# /autoop [channel]
sub main::cmd_autoop {
    debug "cmd_autoop $::args";
    optional_channel or return;
    my $c = lc xgetarg;
    have_ops $c or return;
    $Autoop or return;
    userhost [keys %{ $Chan_user{$c} }], sub {
	autoop_try $c, $::who, "$::user\@$::host", 1;
    };
}
addcmd 'autoop';
addhelp 'autoop', '[channel]',
q{Uses your autoop list to op and voice people on the current channel.
Since this happens automatically you don't normally have to do this, this
command is useful if you'd had autoopping disabled, or if there's a bug
in the system.
};

# Try an /autoop after receiving ops.
add_hook '+op', sub {
    my ($c, $n) = @_;

    timer 10, sub { main::cmd_autoop $c } if ieq $n, $::nick;
};

add_hook '-voice', sub {
    my ($c, $n) = @_;
    my ($now);

    return unless $Autovoice;
    return unless exists $Autovoice{$c};
    $now = time;
    userhost $n, sub {
	$Autovoice{$c}{mask_to_re ban_pattern $::who, $::user, $::host}
	    = $now;
    };
};

add_hook '+voice', sub {
    my ($c, $n) = @_;

    return unless $Autovoice{$c};
    userhost $n, sub {
	delete $Autovoice{$c}{mask_to_re
				ban_pattern $::who, $::user, $::host};

	# If that was the last pattern, drop the hash ref.
	undef $Autovoice{$c} unless %{ $Autovoice{$c} };
    }
};

# Allow ops on autovoiced channels to control your autovoice delay with
# a specially formatted /msg.
#
#     autovoice		report current value
#     autovoice N	set it to N
#     autovoice +N	add N seconds to the delay
#     autovoice -N	remove N seconds from the delay

sub main::hook_autovoice_control_msg {
    my ($msg) = @_;
    return unless $msg =~ s/^\s*autovoice\b//i;
    return unless $Autovoice_control;
    debug "autovoice_control_msg [$msg] who [$::who]";

    if (!grep { $Chan_op{$_}{$::who} } keys %Autovoice) {
	notice $::who, "You aren't an op on a channel I'm autovoicing.";
	return;
    }

    if (ref $Autovoice_delay) {
	notice $::who, "My autovoice delay is a code ref, "
	    	    	. "so remote control isn't available.";
	return;
    }

    my $new;
    if ($msg =~ /^\s*$/) {
	notice $::who, "Current autovoice delay is $Autovoice_delay.";
    }
    elsif ($msg =~ /^\s*(\d+)\s*$/) {
	$new = $1;
    }
    elsif ($msg =~ /^\s*([+-]\s*\d+)\s*$/) {
	my $n = $1;
	$n =~ s/\s+//g;
	$new = $Autovoice_delay + $n;
    }
    else {
	notice $::who, "Unrecognized autovoice command, use:  `autovoice', "
	    	    	. "`autovoice N', `autovoice +N', `autovoice -N'.";
    }

    if (defined $new) {
	if ($new < 0) {
	    notice $::who, "Ignoring invalid delay $new.";
	}
	elsif ($new < 1) {
	    notice $::who, "Ignoring too-low delay $new, "
	    	    	    . "it would cause +v floods on netjoins.";
	}
	else {
	    doset 'autovoice_delay', $new;
	    notice $::who, "Autovoice delay set to $Autovoice_delay.";
	}
    }
}
addhook 'msg', 'autovoice_control_msg';

1;
