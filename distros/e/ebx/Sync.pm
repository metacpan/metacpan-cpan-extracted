# $File: //depot/ebx/Sync.pm $ $Author: clkao $
# $Revision: #83 $ $Change: 2072 $ $DateTime: 2001/10/15 09:43:21 $

package OurNet::BBSApp::Sync;
require 5.006;

$VERSION = '0.87';

use strict;
use integer;

use IO::Handle;
use Mail::Address;
use OurNet::BBS;

=head1 NAME

OurNet::BBSApp::Sync - Sync between BBS article groups

=head1 SYNOPSIS

    my $sync = OurNet::BBSApp::Sync->new({
        artgrp      => $local->{boards}{board1}{articles},
        rartgrp     => $remote->{boards}{board2}{articles},
        param       => {
	    lseen   => 0,
	    rseen   => 0,
	    remote  => 'bbs.remote.org',
	    backend => 'BBSAgent',
	    board   => 'board2',
	    lmsgid  => '',
	    msgids  => {
	    	articles => [
		    '<20010610005743.6c+7nbaJ5I63v5Uq3cZxZw@geb.elixus.org>',
		    '<20010608213307.suqAZQosHH7LxHCXVi1c9A@geb.elixus.org>',
		],
		archives => [
		    '<20010608213307.suqAZQosHH7LxHCXVi1c9A@geb.elixus.org>',
		    '<20010608213307.suqAZQosHH7LxHCXVi1c9A@geb.elixus.org>',
		],
            },
        },
        force_fetch => 0,
	force_send  => 0,
	force_none  => 0,
	msgidkeep   => 128,
	recursive   => 0,
	clobber	    => 1,
        backend     => 'BBSAgent',
        logfh       => \*STDOUT,
	callback    => sub { },
    });

    $sync->do_fetch('archives');
    $sync->do_send;

=head1 DESCRIPTION

B<OurNet::BBSApp::Sync> performs a sophisticated synchronization algorithm
on two L<OurNet::BBS> ArticleGroup objects. It operates on the first one
(C<lartgrp>)'s behalf, updates what's being done in the C<param> field, 
and attempts to determine the minimally needed transactions to run.

The two methods, L<do_fetch> and L<do_send> could be used independently.
Beyond that, note that the interface might change in the future, and
currently it's only a complement to the L<ebx> toolkit.

=head1 BUGS

Lots. Please report bugs as much as possible.

=cut

use fields qw/artgrp rartgrp param backend logfh msgidkeep hostname
              force_send force_fetch force_none clobber recursive callback/;

use constant SKIPPED_HEADERS =>
    ' name header xid id xmode idxfile time mtime btime basepath'.
    ' dir hdrfile recno ';
use constant SKIPPED_SIGILS => ' ¡» ¡· ¡º ';

sub new {
    my $class = shift;
    my OurNet::BBSApp::Sync $self = fields::new($class);

    %{$self} = %{$_[0]};

    $self->{msgidkeep} ||= 128;
    $self->{hostname}  ||= $OurNet::BBS::Utils::hostname || 'localhost';
    $self->{logfh}     ||= IO::Handle->new->fdopen(fileno(STDOUT), 'w');
    $self->{logfh}->autoflush(1);

    return $self;
}

# FIXME: use sorted array and bsearch here.
sub nth {
    my ($ary, $ent) = @_;

    no warnings 'uninitialized';

    foreach my $i (0 .. $#{$ary}) {
	return $i if $ary->[$i] eq $ent;
    }

    return -1;
}

sub do_retrack {
    my ($self, $rid, $myid, $low, $high) = @_;
    my $logfh = $self->{logfh};

    return $low - 1 if $low > $high;

    my $try = ($low + $high) / 2;
    my $msgid = eval {
	my $art = $rid->[$try];
	UNIVERSAL::isa($art, 'UNIVERSAL') 
	    ? $art->{header}{'Message-ID'} : undef;
    };

    return (($msgid && nth($myid, $msgid) == -1)
        ? $low - 1 : $low) if $low == $high;

    $logfh->print("  [retrack] #$try: try in [$low - $high]\n");

    if ($msgid and nth($myid, $msgid) != -1) {
        return $self->do_retrack($rid, $myid, $try + 1, $high);
    }
    else {
        return $self->do_retrack($rid, $myid, $low, $try - 1)
    }
}

sub retrack {
    my ($self, $rid, $myid, $rseen) = @_;
    my $logfh = $self->{logfh};

    $logfh->print("  [retrack] #$rseen: checking\n");

    return $rseen if (eval {
	$rid->[$rseen]{header}{'Message-ID'}
    } || '') eq $myid->[-1];

    $self->do_retrack(
	$rid, 
	$myid, 
	($rseen > $self->{msgidkeep}) 
	    ? $rseen - $self->{msgidkeep} : 0, 
	$rseen - 1
    );
}

sub do_send {
    my $self     = $_[0];
    my $artgrp   = $self->{artgrp};
    my $rartgrp  = $self->{rartgrp};
    my $param    = $self->{param};
    my $backend  = $self->{backend};
    my $logfh    = $self->{logfh};
    my $rbrdname = $param->{board};
    my ($lseen, $lseen_last) = split(',', $param->{lseen}, 2);
    my ($lmsgid, $lmsgid_last) = split(',', $param->{lmsgid}, 2);

    return unless $lseen eq int($lseen || 0); # must be int
    $lseen = $#{$artgrp} + 1 if $#{$artgrp} < $lseen;

    $logfh->print("     [send] checking...\n");

    $param->{lseen} = $lseen;
    $param->{lmsgid} = $lmsgid;

    if ($lmsgid || $lmsgid_last) {
	my $art;
	if ($lseen_last and ($lseen == 0 or
	    ($art = eval { $artgrp->[$lseen - 1] } and
	    $art->{header}{'Message-ID'} eq $lmsgid)) and
	    $art = eval { $artgrp->[$lseen_last - 1] } and
	    $art->{header}{'Message-ID'} eq $lmsgid_last) {
	    $lseen = $lseen_last;
	    print "     [send] (cached) checking from $lseen_last\n";
	}
	else {
	    ++$lseen;

	    while (--$lseen > 0) {
		my $art = eval { $artgrp->[$lseen - 1] } or next;

		$logfh->print("     [send] #$lseen: looking back\n");
		last unless $lmsgid lt $art->{header}{'Message-ID'};
	    }

	    $param->{lseen} = $lseen;
	}
    }

    while ($lseen++ <= $#{$artgrp}) {
        my $art = eval { $artgrp->[$lseen - 1] } or next;
        next unless defined $art->{title}; # sanity check

	$lseen_last = $lseen;
	$lmsgid_last = $art->{header}{'Message-ID'};

        next unless (
	    $self->{force_send} or (
		index(($art->{header}{'X-Originator'} || ''),  
		    "$rbrdname.board\@$param->{remote}") == -1 and
		($backend ne 'NNTP' or !$art->{header}{Path})
	    )
	);

	$logfh->print("     [send] #$lseen: posting $art->{title}\n");

	my %xart = ( header => { %{$art->{header}} } );
	safe_copy($art, \%xart);
	$xart{body} = $art->{body};

	if ($self->{clobber}) {
	    my $adr = (Mail::Address->parse($xart{header}{From}))[0];

	    $xart{header}{From} = (
		$adr->address.'.bbs@'.$self->{hostname}.' '.$adr->comment
	    ) if $adr and index($adr->address, '@') == -1;
	}

	my $xorig = $artgrp->board.'.board@'.$self->{hostname};

	if (index(' External NNTP MELIX DBI ', $backend) > -1
	    or ($backend eq 'OurNet' 
	        and index(' NNTP MELIX DBI ', $rartgrp->backend) > -1))
	{
	    $xart{header}{'X-Originator'} = $xorig;
	}
	elsif (rindex($xart{body}, "--\n¡°") > -1) {
	    chomp($xart{body});
	    chomp($xart{body});
	    $xart{body} .= "\n¡° X-Originator: $xorig";
	}
	else {
	    $xart{body} .= "--\n¡° X-Originator: $xorig";
	}

	eval { $rartgrp->{''} = \%xart } unless $self->{force_none};

	if ($@) {
	    chomp(my $error = $@);
	    $logfh->print("     [send] #$lseen: can't post ($error)\n");
	}
	else {
	    $param->{lseen}  = $lseen;
	    $param->{lmsgid} = $art->{header}{'Message-ID'};

	    $self->{callback}->($self, 'post')
		if UNIVERSAL::isa($self->{callback}, 'CODE'); # callback
	}
    }

    $param->{lseen} .= ",$lseen_last";
    $param->{lmsgid} .= ",$lmsgid_last";

    return 1;
}

sub do_fetch {
    my ($self, $dir, $depth) = @_;

    my $artgrp	 = $self->{artgrp};
    my $rartgrp	 = $self->{rartgrp};
    my $param	 = $self->{param};
    my $backend	 = $self->{backend};
    my $logfh	 = $self->{logfh};
    my $msgids	 = $param->{msgids}{$dir} ||= [];
    my $btimes	 = $param->{msgids}{'__BTIME__'} ||= {};
    my $rbrdname = $param->{board}; # remote board name
    my $padding	 = '    ' x (++$depth);

    my ($first, $last, $rseen);

    if ($backend eq 'NNTP') {
	$first	= $rartgrp->first;
	$last	= $rartgrp->last;
	$rseen	= defined($param->{rseen})
	    ? $param->{rseen} : ($last - $self->{msgidkeep});
    }
    else {
	$first	= 0; # for normal sequential backends
	$last	= $#{$rartgrp};
	$rseen	= $param->{rseen};
    }

    return unless defined($rseen) and length($rseen); # requires rseen

    $rseen += $last + 1 if $rseen < 0;     # negative subscripts
    $rseen = $last + 1  if $rseen > $last; # upper bound

    $logfh->print($padding, "[fetch] #$param->{rseen}: checking\n");

    if ($msgids and @{$msgids}) {
	if ($rseen and my $msgid = eval {
	    $rartgrp->[$rseen - 1]{header}{'Message-ID'}
	}) {
	    $msgid = "<$msgid>" if substr($msgid, 0, 1) ne '<';
	    $rseen = $self->retrack($rartgrp, $msgids, $rseen - 1)
		if $msgid ne $msgids->[-1];
	}
    }
    else { # init
	my $rfirst = (($rseen - $first) > $self->{msgidkeep}) 
	    ? $rseen - $self->{msgidkeep} : $first;

        my $i = $rfirst;

        while($i < $rseen) {
            $logfh->print($padding, "[fetch] #$i: init");

	    eval {
		my $art = $rartgrp->[$i++];
		$art->refresh;
		$self->update_msgid(
		    $dir, $art->{header}{'Message-ID'}, 'init'
		);
	    };

            $logfh->print($@ ? " failed: $@\n" : " ok\n");
        }

        $rseen = $i;
    }

    $rseen = 0 if $rseen < 0;

    $logfh->print($padding,
	($rseen <= $last)
	    ? "[fetch] range: $rseen..$last\n"
	    : "[fetch] nothing to fetch ($rseen > $last)\n"
    );

    return if $rseen > $last;

    my $xorig = $artgrp->board.".board\@$self->{hostname}";

    while ($rseen <= $last) {
        my ($art, $btime);

        $logfh->print($padding, "[fetch] #$rseen: reading");

	eval { 
	    $art = $rartgrp->[$rseen];
	    $art->refresh;
	};

	if ($@) {
            $logfh->print("... nonexistent, failed\n");
	    ++$rseen; next;
        }

	my ($msgid, $rhead);

	my $is_group = ($art->REF =~ m|ArticleGroup|);

	if ($is_group) {
	    $btime = $art->btime; # saves its modification time

	    $art = {
	    	date   => $art->{date},
		author => $art->{author},
		title  => $art->{title},
	    };

	    # not really a message so won't have MSGID; let's fake one here.
	    $msgid = OurNet::BBS::Utils::get_msgid(
		@{$art}{qw/date author title/},
		$rbrdname,
		$param->{remote},
	    );
	}
	else {
	    $msgid = $art->{header}{'Message-ID'}; # XXX voodoo refresh

	    $art = $art->SPAWN;
	    $rhead = $art->{header};

	    if ($rhead->{'Message-ID'} ne $msgid) {
		# something's very, very wrong
		print "... lacks Message-ID, skipped\n";
		++$rseen; next;
	    }

	    $msgid = "<$msgid>" if substr($msgid, 0, 1) ne '<'; # legacy
	}

	if ($self->{force_fetch} or
	    rindex($art->{body}, "X-Originator: $xorig") == -1 and
	    nth($msgids, $msgid) == -1 and
		($rhead->{'X-Originator'} || '') ne $xorig
	) {
	    my (%xart, $xartref);

	    $self->update_msgid($dir, $msgid, 'fetch');

	    if (!$is_group) {
		%xart = (header => $rhead); # maximal cache
		safe_copy($art, $xartref = \%xart);

		# the code below makes us *really* want a ??= operator.
		unless (defined $xart{body} or 
		        defined $xart{header}{Subject}) {
		    print "... article empty, skipped\n";
		    ++$rseen; next;
		}

		if ($dir eq 'archives' and $xart{header}{Subject} eq '#') {
		    print "... '#' metadata, skipped\n";
		    ++$rseen; next;
		}

		$xart{header}{'X-Originator'} = 
		    "$rbrdname.board\@$param->{remote}" if $backend ne 'NNTP';

		$xart{body} =~ s|^((?:: )+)|'> ' x (length($1)/2)|gem;
		$xart{nick} = $1 if $xart{nick} =~ m/^\s*\((.*)\)$/;

		if ($self->{clobber} and $backend ne 'NNTP') {
		    $xart{author} .= "." unless !$xart{author}
			or substr($xart{author}, -1) eq '.';
		    $xart{header}{From} = 
			"$xart{author}bbs\@$param->{remote}" . 
			($xart{nick} ? " ($xart{nick})" : '')
			    unless $xart{header}{From} =~ /^[^\(]+\@/;
		}
		elsif (0) { # XXX: not yet supported
		    $xart{header}{'Reply-To'} = 
			"$xart{author}.bbs\@$param->{remote}" . 
			(defined $xart{nick} ? " ($xart{nick})" : '')
			    unless $xart{header}{From} =~ /^[^\(]+\@/;
		}

		$artgrp->{''} = $xartref unless $self->{force_none};
		$logfh->print(" $xart{title}\n");
	    }
	    else { # ArticleGroup code
		%xart = %{$art};

		# strip down unnecessary sigils
		$xart{title} = substr($xart{title}, 3)
		    if index(SKIPPED_SIGILS, substr($xart{title}, 0, 3)) > -1;

		$xartref = bless(\%xart, $artgrp->module('ArticleGroup'));

		$artgrp->{''} = $xartref unless $self->{force_none};
		$logfh->print(" $xart{title}\n");

		$self->fetch_archive(
		    $artgrp->[-1],
		    $rartgrp->[$rseen],
		    0, # start anew
		    $msgid, $depth, $btime, $btimes,
		);
	    }
        }
        elsif ($is_group and $self->{recursive}
	       and $btimes->{$msgid}[0] != $btime
	) {
	    $logfh->print(" $art->{title} (updating)\n");

	    $self->fetch_archive(
		$artgrp->{$btimes->{$msgid}[1]}, # name
		$rartgrp->[$rseen],
		-$self->{msgidkeep}, # update cached only
		$msgid, $depth, $btime, $btimes,
	    );
        }
        else {
            $logfh->print("... duplicate, skipped\n");
	    $self->update_msgid($dir, $msgid, 'duplicate');
        }

	$param->{rseen} = ++$rseen;
    }

    return $artgrp->[-1] || 1; # must be here to re-initialize this board
}

sub update_msgid {
    my ($self, $dir, $msgid, $reason) = @_;

    push @{$self->{param}{msgids}{$dir}}, $msgid;

    $self->{callback}->($self, $reason)
	if UNIVERSAL::isa($self->{callback}, 'CODE'); # callback
}

sub fetch_archive {
    my $self = shift;
    return unless $self->{recursive};

    my ($artgrp, $rartgrp) = @{$self}{qw/artgrp rartgrp/};

    $self->{artgrp}  = shift;
    $self->{rartgrp} = shift;
    $self->{param}{rseen} = shift;

    my ($msgid, $depth, $btime, $btimes) = @_;

    $self->do_fetch($msgid, $depth);
    $btimes->{$msgid} = [
	$btime, $self->{artgrp}->name,
    ];

    @{$self}{qw/artgrp rartgrp/} = ($artgrp, $rartgrp);
}

sub safe_copy {
    my ($from, $to) = @_;

    while (my ($k, $v) = each (%{$from})) {
	$to->{$k} = $v if index(
	    SKIPPED_HEADERS, " $k "
	) == -1;
    }
}

1;

__END__

=head1 SEE ALSO

L<ebx>, L<OurNet::BBSApp::PassRing>, L<OurNet::BBS>

=head1 AUTHORS

Chia-Liang Kao E<lt>clkao@clkao.org>,
Autrijus Tang E<lt>autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2001 by Chia-Liang Kao E<lt>clkao@clkao.org>,
                  Autrijus Tang E<lt>autrijus@autrijus.org>.

All rights reserved.  You can redistribute and/or modify
this module under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
