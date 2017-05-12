# $Id: Kick.pm,v 1.5 2000-06-30 23:53:02-04 roderick Exp $
#
# Copyright (c) 1997-2000 Roderick Schertler.  All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

use strict;

package Sirc::Kick;

use Exporter		();
use Sirc::Chantrack	qw(%Chan_op);
use Sirc::Util		qw(addcmd arg_count_error ban_pattern docommand
			    have_ops optional_channel timer userhost xtell);

use vars qw($VERSION @ISA @EXPORT_OK $Debug);

BEGIN {
    $VERSION  = do{my@r=q$Revision: 1.5 $=~/\d+/g;sprintf '%d.'.'%03d'x$#r,@r};
    $VERSION .= '-l' if q$Locker:  $ =~ /: \S/;

    # ban_pattern() is exportable because it used to live here.
    @ISA		= qw(Exporter);
    @EXPORT_OK		= qw(ban_pattern kb kbtmp);
    $Debug		= 0;
}

sub debug {
    xtell 'kick debug ' . join '', @_
	if $Debug;
}

sub kb {
    debug "kb @_";
    unless (@_ == 2 || @_ == 3) {
	arg_count_error undef, '2 or 3', @_;
	return;
    }
    my ($channel, $n, $reason) = @_;
    have_ops $channel or return;
    userhost $n, sub {
	my $pattern = ban_pattern $::who, $::user, $::host;
	docommand "^alias unban mode $channel -b $pattern";
	docommand "mode $channel -o+b $::who $pattern";
	docommand "kick $channel $::who $reason";
    };
}
docommand "^alias unban /eval Sirc::Util::tell_question 'No previous pattern'";

# kickban, /kb [channel] nick reason

sub main::cmd_kb {
    debug "cmd_kb $::args";
    optional_channel or return;
    kb split ' ', $::args, 3;
}
addcmd 'kb';

# kbtmp channel nick reason

sub kbtmp {
    debug "kbtmp @_";
    unless (@_ == 2 || @_ == 3) {
	arg_count_error undef, '2 or 3', @_;
	return;
    }
    my ($channel, $n, $reason) = @_;
    have_ops $channel or return;
    userhost $n, sub {
	my $pattern = "$n!*\@*";
	my $op = $Chan_op{$channel}{$n};
    	docommand "mode $channel "
	    	    . ($op ? '-o' : '')
		    . '+b'
		    . ($op ? " $n": '')
		    . " $pattern";
    	docommand "kick $channel $n $reason";
	timer 10, sub { docommand "mode $channel -b $pattern" };
    };
}

# /k [channel] nick comment

sub main::cmd_k {
    debug "cmd_k $::args";
    optional_channel or return;
    kbtmp split ' ', $::args, 3;
}
addcmd 'k';

1;
