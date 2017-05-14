#!/usr/bin/perl
# Copyright (c) 2006 Sampo Kellomaki (sampo@iki.fi). All Rights Reserved.
# 1. Thread activity in AK lines, busiest thread
# 2. All per-thread time deltas over -w limit
# 3. Bar graph of total and per thread activity per time slice (e.g. ms)
# 4. Lock holding times, contention, frequency, time contribution, bell curve...
# 5. Lock affinity between threads
#
# TODO
# * call-anal.pl local_callgraph: potential locks held, locks that may be taken
#
# mpage -1 -l -L 200 -W 300 -S new-edit.lock | nc kotips 9100
# mpage -1 -L 300 -W 200 -S new-edit.lock | nc kotips 9100

use Data::Dumper;

$tag = 'ALLSEEN';
$format = 'full';
$slice = 100;
$norm = 100;   # Normalization factor
$w_usec = 1000;
$narrative_lines = 498;
$compact = 0;
$max_cols = 20;

$usage = <<USAGE;
Usage: ak-lock.pl [OPTS] <ak.out
E.g:   ak-lock.pl -w 10000 -t ALLSEEN <sal_monte.out
  -c       Compact time scale in lock narratives
  -i THR   Specify a thread of interest. Can be specified multiple times.
           If -i is not specified, all threads are considered interesting.
  -l LINES How many first lines to show in narrative histories. Default $narrative_lines.
  -n NORM  Normalization factor for scaling the bar graphs. Default $norm
  -r B E   Analyze range of time. B is start, E is end time in HHMMSSUUUUUU format.
  -s USEC  Time slice for activity bargraph. Default $slice us
  -t TAG   What tag to start the analysis with. Default is $tag. Try also FIRSTWRAP.
  -w USEC  Wait time. Specify that only delays longer than USEC are output (default $w_usec)
USAGE
    ;

while (defined $ARGV[0]) {
    if ($ARGV[0] eq '-c') { shift; $compact = !$compact; next; }
    if ($ARGV[0] eq '-i') { shift; $t = shift; $interest{$t} = 1; next; }
    if ($ARGV[0] eq '-l') { shift; $narrative_lines = shift; next; }
    if ($ARGV[0] eq '-n') { shift; $norm = shift; next; }
    if ($ARGV[0] eq '-q') { shift; ++$quiet; next; }  # Do not invoke in vain! The disclaimer is important! --Sampo
    if ($ARGV[0] eq '-r') { shift; undef $tag; $begin_time = shift; $end_time = shift; next; }
    if ($ARGV[0] eq '-s') { shift; $slice = shift; next; }
    if ($ARGV[0] eq '-t') { shift; $tag = shift; next; }
    if ($ARGV[0] eq '-w') { shift; $w_usec = shift; next; }
    die "Unknown option($ARGV[0])\n$usage";
}

### Output preamble, displaying copyright, warranty, confidentiality and other info

print "A P P L I C A T I O N  B L A C K (K) B O X   A N A L Y S I S   R E P O R T   (R2)\n" if !$quiet;
print "#################################################################################\n" if !$quiet;
print 'Generated using ak-lock.pl $Id$' . "\n\n" if !$quiet;

$_ = <STDIN>;
print if !/^PREAMBLE (\S+)/ && !$quiet;
$format = $1 if defined $1;

while ($_ = <STDIN>) {
    last if /^END_PREAMBLE/o;
    print if !$quiet;
}

print <<CAVEAT if !$quiet;

The data in this analysis is based on logged activity of each thread. Threads
have different roles and may log more or less verbosely based on the role
and possibly debugging related command line flags. Thus, if a thread appears
busy, you can only judge that in relation to other threads with the same role.
CAVEAT
    ;

# Logarithmic bars. oo == infinite or out of scale
$bar10 = '----------==========**********##########$$$$$$$$$$ oo';
$bar5 = '-----=====*****#####$$$$$ oo';
$bar2 = '--==**##$$ oo';
$bar1 = '-=*#$ oo';
%pdu_state_tab = ( C=>':', l=>'|', L=>'|', U=>'.', M=>'.', m=>' ', F=>' ', '='=>' ' );
%state_tab = ( C=>':', l=>'|', L=>'|', U=>'.' );

# First, skip log entries until TAG or Begin time.

if ($tag) {
    while ($_ = <STDIN>) {
	last if /^$tag/o;
    }
    $line = <STDIN>;  # First line
} else {
    while ($line = <STDIN>) {
	analyze_line($line);
	last if $time ge $begin_time;
    }
}

while ($line =~ /^\s*$/) {   # Skip over empty lines
    $line = <STDIN>;
}

sub time_diff {
  my ($t1, $t2, $now) = @_;
  my $ret;
  if ($format eq 'brief') {
      $ret = int(($t1 - $t2) * 1000000);
      goto err if $t1 < $t2;
      return $ret;
  } else {
      my ($hour1, $min1, $sec1, $gnapa1, $usec1) = unpack "A2A2A2AA6", $t1;
      my ($hour2, $min2, $sec2, $gnapa2, $usec2) = unpack "A2A2A2AA6", $t2;
      $usecs1=($hour1*60*60+$min1*60+$sec1)*1000000+$usec1;
      $usecs2=($hour2*60*60+$min2*60+$sec2)*1000000+$usec2;
      $ret = $usecs1-$usecs2;
      goto err if $usecs1 < $usecs2;
      return $ret;
  }
err:
  my ($p, $f, $l) = caller;
  #print "WARNING: later($t1) < earlier($t2). now($now) called from $f:$l\n" if $t1 < $t2;
  return $ret;
}

sub bars_head {
    my $h = sprintf " %s  N   (total)        ", ' ' x length($time);
    my $thr;
    for $thr (sort keys %act) {
	$h .= sprintf " %-7s", $thr;
    }
    return $h . "\n";
}

sub take_lock {
    my ($thr, $time, $lock, $reason) = @_;
    $take{$lock} = $time;
    ++$n{$lock}{$thr};
    ++$reason{$lock}{$reason};
    if (!$holder{$lock} && !keys %{$contend{$lock}}) {
	$holder{$lock} = $thr;
	$narrative{$lock}{$time} .= "$thr L\n";
    } else {
	if ($contend{$lock}{$thr}) {
	    die "WARNING: $lock appears to be already taken/contended by this same thread($thr). Now($time), contended($contend{$lock}{$thr})\n";
	}
	++$contend_n{$lock}{$thr};      # Count number of contentions by thread
	$contend{$lock}{$thr} = $time;  # Mark thread as contending for rest of comput
	$narrative{$lock}{$time} .= "$thr C\n";
	$narrative_note{$lock}{$time} .= " $holder{$lock}";  # Who is causing contention
    }
}

sub let_go_of_lock {
    my ($thr, $time, $lock) = @_;
    if ($holder{$lock}) {
	if ($holder{$lock} eq $thr) {
	    undef $holder{$lock};
	    die "WARNING: take{$lock} not set when unlocking: $thr $time\n" if !$take{$lock};
	    $h_diff = time_diff($time, $take{$lock}, $time);
	} else {
	    #die "$lock appears to be released by different thread than which took it: $time holder($holder{$lock}) unlocker($thr)\n";
	    #print "ADJUST: $thr $time: $lock unlock by different thread than which took it: apparent holder($holder{$lock}) unlocker($thr)\n";
	    
	    # Can be caused by two threads taking lock on same usec. E.g. L1+L2+U2
	    # implies that, in fact, L1 was taken after L2 (and L1 should be contending)
	    # and L2 should NOT be contending.
	    
	    $contend{$lock}{$holder{$lock}} = $time;  # L1 is contending
	    delete $contend{$lock}{$thr};             # L2 not contending.
	    undef $holder{$lock};
	    $h_diff = 0;  # No reliable estimate can be made
	}
	$c_diff = 0;
    } else {   # Determine which of the main lock contenders got it.
	if ($contend{$lock}{$thr}) {
	    # We contended to get the lock. Later it was unlocked and we got the lock.
	    if ($unlock{$lock}) {
		$c_diff = time_diff($unlock{$lock}, $contend{$lock}{$thr}, "$time $unlock_by{$lock} $holder{$lock}");
		if ($c_diff < 0) {  # Obviously there was no contention
		    #print "IGNORE: $thr $time: Ignoring negative contention time($c_diff).\n";
		    $c_diff = 0;
		    $h_diff = time_diff($time, $take{$lock}, $time);
		} else {
		    $h_diff = time_diff($time, $unlock{$lock}, $time);
		}
		$narrative{$lock}{$unlock{$lock}} .= "$thr l\n";
	    } else {
		die "WARNING: $lock was contended and unlocked by thr($thr) time($time), but there is no previous unlock time.\n";
		$c_diff = time_diff($time, $contend{$lock}{$thr}, $time);
		$h_diff = 0; # No reliable estimate can be made, we account all time to contention
	    }
	    delete $contend{$lock}{$thr};
	} else {
	    #die "WARNING: $lock released without being held: $thr $time\nmlh($main_lock_holder) contend(" . Dumper(%main_lock_contend) . ")";
	    print "WARNING: $thr $time: $lock released without apparently being held (wrap around?) contend(".Dumper(%{$contend{$lock}}).")\n" if $rel_wo_held_warn{$lock}{$thr}++;
	    $h_diff = 0;  # No reliable estimate can be made
	    $c_diff = 0;
	}
    }
    $narrative{$lock}{$time} .= "$thr U\n";
    $time{$lock}{$thr} += $h_diff;
    $unlock{$lock} = $time;  # Most recent unlock time: may be the lock time of contender
    $unlock_by{$lock} = $thr;
    #$bin = $h_diff ? log($h_diff)/log(10) : 0;   *** rethink log scaling
    #++$held{$lock}{$bin};
    ++$held_usec{$lock}{$h_diff};
    $held_ts{$lock}{$h_diff} = $time;
    ++$contend_usec{$lock}{$c_diff};
    $contend_ts{$lock}{$c_diff} = $time;
}

sub analyze_line {
    my ($line) = @_;
    return if !$line || substr($line, 0, 1) eq '#';
    if ($format eq 'brief') {
	($thr, $time, $funcline, $op, @rest) = split /\s+/, $line;
	if ($time < $prev_time) {
	    warn "time($time) < prev_time($prev_time)";
	    $time = "1$time";
	}
	$prev_time = $time;
    } else {
	($thr, $yyyymmdd, $time, $fileline, $func, $op, @rest) = split /\s+/, $line;
    }
    return if $thr eq 'ALLSEEN' || $thr eq 'FIRSTWRAP';
    $t_diff = $old{$thr} ? time_diff($time, $old{$thr}, $time) : 0;
    $old{$thr} = $time;   # N.B. $time is either hhmmssuu or ssuu depending on format
    #warn "thr($thr) $line";
    if ($t_diff >= $w_usec) {
	print "  $t_diff \t$line" if !defined %interest || $interest{$thr};
    }
    ++$act{$thr};
    ++$act_slice{$thr};
    ++$activity_in_slice;
    if ($slice && $last_time ne $time && !(($time*1000000) % $slice)) {
	$bars_hdr = bars_head();
	if ($bars_hdr ne $old_bars_hdr) {
	    #warn "new($bars_hdr)\nold($bars_hdr)";
	    $bars .= $bars_hdr;
	    $old_bars_hdr = $bars_hdr;
	}

	$bars .= sprintf " $time %4d %-15s", $activity_in_slice, '#' x ($activity_in_slice/$norm);
	$activity_in_slice = 0;
	for $thr (sort keys %act) {
	    $bars .= sprintf " %3s %-3s", $act_slice{$thr} ? $act_slice{$thr} : '.', '#' x ($act_slice{$thr} / $norm);
	    $act_slice{$thr} = 0;
	}
	$bars .= "\n";
	$last_time = $time;
    }

    if ($op eq 'SHUFF_LOCK') {
	take_lock($thr, $time, 'shuff_lock', $rest[1]);
	return;
    }
    if ($op eq 'SHUFF_UNLOCK') {
	let_go_of_lock($thr, $time, 'shuff_lock');
	return;
    }

    if ($op eq 'MAIN_LOCK') {
	take_lock($thr, $time, 'main_lock', $rest[1]);
	return;
    }
    if ($op eq 'MAIN_UNLOCK') {
	let_go_of_lock($thr, $time, 'main_lock');
	return;
    }

    if ($op =~ /^MEM_LOCK\((?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$1} ne $thr) {
	    $pdu_narr{$time} .= "$thr $1 <$thr>\n";
	    $pdu_thr{$1} = $thr;
	}
	$pdu_narr{$time} .= "$thr $1 M\n";
	(undef, $lock) = split /=/, $rest[1];
	take_lock($thr, $time, "mem_lock_$lock", $rest[3]);
	return;
    }
    if ($op =~ /^MEM_UNLK\((?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$1} ne $thr) {
	    $pdu_narr{$time} .= "$thr $1 <$thr>\n";
	    $pdu_thr{$1} = $thr;
	}
	$pdu_narr{$time} .= "$thr $1 m\n";
	(undef, $lock) = split /=/, $rest[1];
	let_go_of_lock($thr, $time, "mem_lock_$lock");
	return;
    }

    if ($op =~ /^MALLOC\((?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^MEM_FREE\((?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^MEM_FRM_POOL\((?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^MEM_REL\((?:0x)?([0-9a-f]+)\)/) {
	return;
    }

    if ($op eq 'FD_POOL_LOCK') {
	$lock = substr($rest[1], 4);
	take_lock($thr, $time, "fd_pool_$lock", $rest[2]);
	return;
    }
    if ($op eq 'FD_POOL_UNLOCK') {
	$lock = substr($rest[1], 4);
	let_go_of_lock($thr, $time, "fd_pool_$lock");
	return;
    }

    if ($op eq 'THR_POOL_LOCK') {
	$lock = substr($rest[1], 4);
	take_lock($thr, $time, "thr_pool_$lock", $rest[2]);
	return;
    }
    if ($op eq 'THR_POOL_UNLOCK') {
	$lock = substr($rest[1], 4);
	let_go_of_lock($thr, $time, "thr_pool_$lock");
	return;
    }
    
    if ($op eq 'RUN_LOCK') {
	if ($rest[3] eq '[ds_global_get]' || $rest[3] eq '[ds_global_put]') {
	    take_lock($thr, $time, 'global_run_lock', $rest[3]);
	}
	return;
    }
    if ($op eq 'RUN_UNLOCK') {
	if ($rest[3] eq '[ds_global_get]' || $rest[3] eq '[ds_global_put]') {
	    let_go_of_lock($thr, $time, 'global_run_lock');
	}
	return;
    }

    if ($op eq 'GC_START') {
	$gc_start = $time;     # *** does not handle ovelapping gc due to insufficient log data
	return;
    }
    if ($op eq 'GC_END') {
	++$gc_duration{time_diff($time, $gc_start)};
	return;
    }

    if ($op eq 'POLL_OK') {
	($n) = $rest[0] =~ /n_evs=(\d+)/;
	++$poll_ok{$rest[1]}{$n};
	return;
    }

    # I/O objects
    
    if ($op =~ /^DSIO_LOCK\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	++$dsio_lock_reason{$rest[4]};
	return;
    }
    if ($op =~ /^DSIO_UNLK\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^DSQIO_LOCK\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	++$dsqio_lock_reason{$rest[4] || $rest[2]};
	return;
    }
    if ($op =~ /^DSQIO_UNLK\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^READ\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^WR_FRM_BUF\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^ENQ_IO\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {   # poller produces fd
	return;
    }
    if ($op =~ /^DEQ_IO\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {   # consumer consumes fd
	return;
    }
    if ($op =~ /^DSIO_FREE\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^AGAIN\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^EAGAIN_POLL\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^FE\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^THE_IO\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^TRY_TERM\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^CLOSE_CONN\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^TCP_EOF\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^ACCEPT\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^MARK_FOR_TERM\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	return;
    }
    if ($op =~ /^RAISE_XCPT_IO\(([0-9a-f]+).(?:0x)?([0-9a-f]+)\)/) {
	return;
    }

    # PDU life cycle

    if ($op =~ /^NEW_BUF_LK\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/
	|| $op =~ /^NEW_BUF\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	++$pdus{$2};
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 *\n";
	$pdu_creat{$2} = $time;
	$pdu_story{$2} = [];
	$pdu_story_timing{$2} = [];
	return;
    }

    if ($op =~ /^LDAP_TRAILING\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 d\n";
	push @{$pdu_story{$2}}, 'd';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^LDAP_DECODE\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 d\n";
	push @{$pdu_story{$2}}, 'd';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }

    if ($op =~ /^LDAP_ENCODE\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 e\n";
	push @{$pdu_story{$2}}, 'e';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }

    if ($op =~ /^BE_SETUP\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 V\n";
	push @{$pdu_story{$2}}, 'V';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }

    if ($op =~ /^BE_POP\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 v\n";
	push @{$pdu_story{$2}}, 'v';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }

    if ($op =~ /^HK_PROCESS\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 H$1\n";
	push @{$pdu_story{$2}}, "H$1";
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^NEXT_HK\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 h\n";
	push @{$pdu_story{$2}}, 'h';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^CS_REJECT\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 R\n";
	push @{$pdu_story{$2}}, 'R';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^CS_SKIP_SUFFIX\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 z\n";
	push @{$pdu_story{$2}}, 'z';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }

    if ($op =~ /^PDU_LOCK\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 L\n";
	++$pdu_lock_reason{$rest[9]};
	push @{$pdu_story{$2}}, 'L';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^PDU_UNLK\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 U\n";
	push @{$pdu_story{$2}}, 'U';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }

    if ($op =~ /^RUN_LOCK\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 L\n";
	++$pdu_lock_reason{$rest[4]};
	push @{$pdu_story{$2}}, 'L';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^RUN_UNLOCK\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 U\n";
	push @{$pdu_story{$2}}, 'U';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }

    if ($op =~ /^PDU_INVOKE\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 I\n";
	push @{$pdu_story{$2}}, 'I';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^FULL\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 J\n";
	push @{$pdu_story{$2}}, 'J';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^LEAF\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 j\n";
	push @{$pdu_story{$2}}, 'j';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }

    if ($op =~ /^SYNTH_RESP\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 s\n";
	push @{$pdu_story{$2}}, 's';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }

    if ($op =~ /^HOPELESS\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 x\n";
	push @{$pdu_story{$2}}, 'x';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }

    if ($op =~ /^TRY_REL_REQ_ET_PEND_DONE\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 g\n";
	push @{$pdu_story{$2}}, 'g';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }

    if ($op =~ /^PDU_ENQ\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 E\n";
	push @{$pdu_story{$2}}, 'E';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^CHOOSE_BE\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 B\n";
	push @{$pdu_story{$2}}, 'B';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^SCHED_LK\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 S\n";
	push @{$pdu_story{$2}}, 'S';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^FE_POP\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 P\n";
	push @{$pdu_story{$2}}, 'P';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^DQ_TO_WR\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 D\n";
	push @{$pdu_story{$2}}, 'D';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^FE_POP2\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 p\n";
	push @{$pdu_story{$2}}, 'p';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^RM_FRM_Q\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 Q\n";
	push @{$pdu_story{$2}}, 'Q';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^ONE_MORE\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 O\n";
	push @{$pdu_story{$2}}, 'O';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^YANK\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 Y\n";
	push @{$pdu_story{$2}}, 'Y';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }

    if ($op =~ /^ADD_TO_WR\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 W\n";
	push @{$pdu_story{$2}}, 'W';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    
    if ($op =~ /^CLEAN_PDU\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 f\n";
	$bin = int(time_diff($time, $pdu_creat{$2})/100)*100;
	#warn "creat($pdu_creat{$2}) now($time) pdu($1:$2)" if $bin > 100000;
	++$pdu_live_time{$1}{$bin} if $pdu_creat{$2};
	++$n_pdu{$1};
	push @{$pdu_story{$2}}, 'f';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^TRY_REL\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 r\n";
	push @{$pdu_story{$2}}, 'r';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^UNLINK\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 u\n";
	push @{$pdu_story{$2}}, 'u';
	push @{$pdu_story_timing{$2}}, $time;
	return;
    }
    if ($op =~ /^FREE_BUF\(([0-9a-f]+):(?:0x)?([0-9a-f]+)\)/) {
	if ($pdu_thr{$2} ne $thr) {
	    $pdu_narr{$time} .= "$thr $2 <$thr>\n";
	    $pdu_thr{$2} = $thr;
	}
	$pdu_narr{$time} .= "$thr $2 =$1\n";
	return if !$pdu_creat{$2};  # Incomplete history
	
	++$pdu_alloc_time{$1}{int(time_diff($time, $pdu_creat{$2})/100)*100};
	push @{$pdu_story{$2}}, '=';
	push @{$pdu_story_timing{$2}}, $time;

	$story = '*' . join('', @{$pdu_story{$2}});
	$pdu_story_ops{$story} = $pdu_story{$2};  # Copy the array
	++$pdu_story_n{$story};
	#warn "Story($story) length=$#{@{$pdu_story{$2}}} creat($pdu_creat{$2})";

	$now = $pdu_creat{$2};
	$delta = time_diff($time, $now);
	die "Impossible delta($delta) time($time) now($now)" if $delta <= 0;
	#warn "delta($delta) Tmin($pdu_story_Tmin{$story}{'=='})";
	$pdu_story_Tmin{$story}{'=='} = $delta if !defined($pdu_story_Tmin{$story}{'=='})
	    || $delta < $pdu_story_Tmin{$story}{'=='};
	$pdu_story_Tmax{$story}{'=='} = $delta if $delta > $pdu_story_Tmax{$story}{'=='};
	$pdu_story_Ttot{$story}{'=='} += $delta;

	for ($i = 0; $i <= $#{@{$pdu_story{$2}}}; ++$i) {
	    $op = $pdu_story{$2}[$i];
	    $delta = time_diff($pdu_story_timing{$2}[$i], $now);
	    die "Impossible delta($delta) pdu=$2 i=$i time($pdu_story_timing{$2}[$i]) now($now) creat($pdu_creat{$2})" if $delta < 0;
	    $now = $pdu_story_timing{$2}[$i];
	    $pdu_story_Tmin{$story}{$op} = $delta if !defined($pdu_story_Tmin{$story}{$op})
		|| $delta < $pdu_story_Tmin{$story}{$op};
	    $pdu_story_Tmax{$story}{$op} = $delta if $delta > $pdu_story_Tmax{$story}{$op};
	    $pdu_story_Ttot{$story}{$op} += $delta;
	}
	return;
    }
    ++$unexplained_ops{$op};
}

# Narrative Legend
# A=, B=choose_be, C=contend lock, D=dequeue, d=decode, E=enqueue, e=encode F=(was free), f=clean,
# G=, g=TRY_REL_REQ_ET_PEND_DONE, H=hk_process, h=next_hk, I=Invoke, J=Full, j=leaf, K=, L=lock, l=lock after contend,
# M=MemLock, m=MemUnlock, N=, O=one more, o=other, P=fe_populate, p=fe_pop2, Q=rm_fr_q,
# R=CS_Reject, r=try_release, S=sched, s=synth resp, T=thread change,
# U=unlock, u=unlink, V=BE_SETUP, v=be_pop, W=write_pdu, X=raise xcpt, x=hopeless, Y=yank, Z=, z=skip suffix
# '='=free '*'=new

### Process the first line

print "\n1 Thread Delay in Excess of $w_usec us\n===================================\n\n";
print "  Diff   Thr  Time...\n";

$yyyymmdd = 'n/a (brief format)';

$0 ="ak-lock: starting";
analyze_line($line);
if ($format eq 'brief') {
    $first_yyyymmdd = 'n/a (brief format)';
} else {
    $first_yyyymmdd = $yyyymmdd;
}
$first_time = $time;
#warn "first_time($first_time) line($line)";

### Scan all lines and build summary data

while ($line = <STDIN>) {
    analyze_line($line);
    $0 ="ak-lock: line $time";
    last if defined($end_time) && $time ge $end_time;
}
$t_diff = time_diff($time, $first_time, 'conclude');
$0 ="ak-lock: line scan over";

for $k (sort keys %unexplained_ops) {
    print " unexplained($k): $unexplained_ops{$k}\n";
}

print "\n2 Activity Overview\n===================\n\n";
print $bars;
print $bars_hdr;

### Activity by thread

print "WARNING: Date changed during analysis period. Analysis timings are unreliable.\nFirst date $first_yyyymmdd, last date $yyyymmdd.\n" if $first_yyyymmdd ne $yyyymmdd;

# N.B. Total activity by FIRSTWRAP is pointless because all threads have same size buffers.
print "\n3 Total Activity by Thread\n==========================\n\n  Thr   N\n" if !defined($tag) || $tag eq 'ALLSEEN';

$tot = 0;
for $thr (sort keys %act) {
    next if !$thr;
    printf "  %4s %6d\n", $thr, $act{$thr} if !defined($tag) || $tag eq 'ALLSEEN';
    $tot += $act{$thr};
}

### Lock analysis

print "\n4 Locks Contended and Held\n==========================\n";

for $lock (sort keys %narrative) {
    lock_report(++$subsec, $lock);
}

sub bar_len {
    my ($n, $fact) = @_;
    return $fact * log($n?$n:1) / log(10);
}

sub report_lock_time_range_bins {
    my ($bin_width, $upper_lim, $report_lim) = @_;
    while ($i <= $#ticks) {
	$lim += $bin_width;
	last if $lim >= $upper_lim;
	
	my $held = 0;
	my $n_held = 0;
	my $held_note = '';
	my $contend = 0;
	my $n_contend = 0;
	my $contend_note = '';
	
	for (; $i <= $#ticks; ++$i) {
	    last if $ticks[$i] >= $lim;
	    if ($held_usec{$lock}{$ticks[$i]}) {
		$held += $held_usec{$lock}{$ticks[$i]};
		$held_note .= "$held_ts{$lock}{$ticks[$i]} ";
		++$n_held;
	    }
	    if ($contend_usec{$lock}{$ticks[$i]}) {
		$contend += $contend_usec{$lock}{$ticks[$i]};
		$contend_note .= "$contend_ts{$lock}{$ticks[$i]} ";
		++$n_contend;
	    }
	}
	
	if ($n_held && $n_held < $report_lim) {
	    chop $held_note;
	    $held_note = "    ($held_note)";
	} else {
	    $held_note = '';
	}
	if ($n_contend && $n_contend < $report_lim) {
	    chop $contend_note;
	    $contend_note = "    ($contend_note)";
	} else {
	    $contend_note = '';
	}
	
	printf("  %5s %5s %-45s  %5s %-45s\n", $lim - 10,
	       $held    ? $held    : '.', substr($bar10, 0, bar_len($held, 5)) . $held_note,
	       $contend ? $contend : '.', substr($bar10, 0, bar_len($contend, 5)). $contend_note);
    }
}

sub lock_report {
    my ($subsec, $lock) = @_;
    print "\n4.$subsec $lock\n----------------------\n";
    
    print "\n4.$subsec.1 $lock contended & held (us, log10 bars)\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
    print "  us        N contended                                          N held\n";
    
    %ticks = ();
    for $k (keys %{$held_usec{$lock}}) {
	$ticks{$k} = 1;
    }
    for $k (keys %{$contend_usec{$lock}}) {
	$ticks{$k} = 1;
    }
    
    @ticks = sort { $a <=> $b } keys %ticks;
    for ($i = 0; $i <= $#ticks; ++$i) {
	last if $ticks[$i] >= 10;
	printf("  %5s %5s %-45s  %5s %-45s\n", $ticks[$i],
	       $held_usec{$lock}{$ticks[$i]} ? $held_usec{$lock}{$ticks[$i]} : '.',
	       substr($bar10, 0, bar_len($held_usec{$lock}{$ticks[$i]}, 5)),
	       $contend_usec{$lock}{$ticks[$i]} ? $contend_usec{$lock}{$ticks[$i]} : '.',
	       substr($bar10, 0, bar_len($contend_usec{$lock}{$ticks[$i]}, 5)));
    }
    
    print "  10-99 us, with 10 us bins\n";
    
    $lim = 10;
    while ($i <= $#ticks) {
	$lim += 10;
	last if $lim > 99;
	
	$held = $contend = 0;
	for (; $i <= $#ticks; ++$i) {
	    last if $ticks[$i] >= $lim;
	    $held += $held_usec{$lock}{$ticks[$i]};
	    $contend += $contend_usec{$lock}{$ticks[$i]};
	}
	printf("  %5s %5s %-45s  %5s %-45s\n", $lim - 10,
	       $held    ? $held    : '.', substr($bar10, 0, bar_len($held, 5)),
	       $contend ? $contend : '.', substr($bar10, 0, bar_len($contend, 5)));
    }

    print "  Summary: 100-999us, with 100us bins\n";
    report_lock_time_range_bins(100, 1000, 3);
    print "  Summary: 1000-4999us, with 500us bins\n";
    report_lock_time_range_bins(500, 5000, 3);
    print "  Summary: 5-10ms, with 1ms bins\n";
    report_lock_time_range_bins(1000, 10000, 3);
    print "  Summary: over 10ms, with 10ms bins\n";
    report_lock_time_range_bins(10000, 1000000000, 3);
    
    print "\n4.$subsec.2 $lock by number of times taken, avg, and total held (log10 bars)\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
    print "  Thread     N                           Avg (us)                    Total held (us)\n";
    
    for $thr (sort keys %{$n{$lock}}) {
	$n = $n{$lock}{$thr};
	$t = $time{$lock}{$thr};
	$avg = $t / $n;
	printf(" %5s %7d %-25s %3.1f %-20s %7d %-20s\n", $thr,
	       $n,   substr($bar5,  0,  5 * log($n)         / log(10)),
	       $avg, substr($bar5,  0, 20 * (log(1+$avg)) / log(10)),
	       $t,   substr($bar5,  0,  5 * log($t)         / log(10)));
    }

    print "\n4.$subsec.3 $lock by reason taken (log10 bars)\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
    print "  Reason                           N\n";
    
    for $reason (sort keys %{$reason{$lock}}) {
	$n = $reason{$lock}{$reason};
	printf(" %30s %7d %-25s\n", $reason, $n, substr($bar5, 0, 5 * log($n) / log(10)));
    }

    print "\n4.$subsec.4 $lock narrative history (lines 100..".($narrative_lines+100)
	.")\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
    
    my $hdr  = ' ' . (' ' x length($time));
    my @thrs = sort keys %act;
    for $thr (@thrs) {
	$hdr .= sprintf " %-7s", $thr;
	$state{$thr} = ' ';
    }
    $hdr .= "\n";
    
    print $hdr;
    my $n = 0;
    my $last_time = 0;
    @ticks = sort keys %{$narrative{$lock}};
    $n_start = (length @ticks > $narrative_lines + 100) ? 100 : 0;
    for $time (@ticks) {
	if (!$compact && $last_time) {   # Print inactive usecs
	    for (; $last_time < $time; $last_time += 0.000001) {
		printf "  %.6f", $last_time;
		for $thr (@thrs) {
		    printf " %-7s", $state{$thr};
		}
		print "-\n";
	    }
	}
	$last_time = $time + 0.000001;

	for $thr (@thrs) {
	    $thr_act{$thr} = '';
	}
	@evts = split /\n/, $narrative{$lock}{$time};
	for $evt (@evts) {
	    ($thr, $e) = split /\s+/, $evt;
	    $thr_act{$thr} .= $e;
	    $state{$thr} = $state_tab{$e};
	}
	next if --$n_start > 0;

	print "  $time";
	for $thr (@thrs) {
	    printf " %-7s", $thr_act{$thr} ? $thr_act{$thr} : $state{$thr};
	}
	print "\n";
	print $hdr if ++$n % 100 == 0;
	last if $n > $narrative_lines;
    }
    
    print $hdr;
    print <<LEGEND;

  Legend: L=lock taken straight, C=Locking attempted but contention,
          l=lock taken after contention, U=unlock, .=no relevant activity.
LEGEND
    ;
}

$0 ="ak-lock: PDUs";
print "\n5 PDUs\n======\n\n";

@pdus = sort keys %pdus;
#warn "pdus: " . Dumper(\@pdus);

print "\n5.1 Types of PDUs\n----------------\n\n";

print "  op       N (log10 bars)\n";
$tot = 0;
for $op (sort keys %n_pdu) {
    printf " %3s %7d %s\n", $op, $n_pdu{$op}, substr($bar10, 0, 5 * log($n_pdu{$op}) / log(10));
    $tot += $n_pdu{$op};
}
printf "\nTotal PDUs processed: %d (%d ops/sec)\n", $tot, $tot * 10000000 / $t_diff;
printf "Number of PDU objects used: %d (reused %.1f times)\n", $#pdus+1, $tot/$#pdus+1;

print "\n5.2 PDU lock by reason taken\n----------------------------\n\n";
print "  Reason                           N (log10 bars)\n";

for $reason (sort keys %pdu_lock_reason) {
    $n = $pdu_lock_reason{$reason};
    printf(" %30s %7d %-25s\n", $reason, $n, substr($bar5, 0, 5 * log($n) / log(10)));
}

#for $pdu (@pdus) {  print "pdu($pdu)\n"; }

print "\n5.3 PDU Stories\n---------------\n\n";

print "\n5.3.1 PDU life time and allocated time by operation\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";

%ops = ();
for $k (keys %pdu_live_time) {
    $ops{$k} = 1;
}
for $k (keys %pdu_alloc_time) {
    $ops{$k} = 1;
}

for $op (sort keys %ops) {
    printf "\n  %-3s us        N live (log10 bars)               N allocated (log10 bars)\n", $op;

    %ticks = ();
    for $k (keys %{$pdu_live_time{$op}}) {
	$ticks{$k} = 1;
    }
    for $k (keys %{$pdu_alloc_time{$op}}) {
	$ticks{$k} = 1;
    }
    
    $live_tot = $alloc_tot = 0;
    for $usec (sort { $a <=> $b } keys %ticks) {
	$live  = $pdu_live_time{$op}{$usec};
	$alloc = $pdu_alloc_time{$op}{$usec};
	$live_tot += $live;
	$alloc_tot += $alloc;
	printf("  %7d %7s %-25s %7s %-25s\n", $usec,
	       $live?$live:'',    substr($bar10, 0,  5 * log(1+$live)  / log(10)),
	       $alloc?$alloc:'',  substr($bar10, 0,  5 * log(1+$alloc) / log(10)));
    }
    printf "  TOTALS:           %d                         %d\n", $live_tot, $alloc_tot;
}

print "\n5.3.2 Summary of PDU Stories\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";

print "         N (log10 bars)                          TAmin     TAavg   TAmax       Story\n";
for $story (sort keys %pdu_story_n) {
    printf("  %7d %-40s %5d %9.1f %7d  %7d %s\n",
	   $pdu_story_n{$story},
	   substr($bar10, 0, 5 * log(1+$pdu_story_n{$story}) / log(10)),
	   $pdu_story_Tmin{$story}{'=='},
	   $pdu_story_Ttot{$story}{'=='} / $pdu_story_n{$story},
	   $pdu_story_Tmax{$story}{'=='},
	   $story);
}

print "\n5.3.3 PDU Story Timings\n~~~~~~~~~~~~~~~~~~~~~~~\n";

for $story (sort keys %pdu_story_n) {
    print "\n  Story: $story (N=$pdu_story_n{$story})\n    op    Tmin      Tavg    Tmax (Tavg log10 bar)\n";
    printf "    %-4s ", '*';
    %op_count = ();
    for $op (@{$pdu_story_ops{$story}}) {
	++$op_count{$op};
    }
    for $op (@{$pdu_story_ops{$story}}) { #@{$pdu_story{$2}}
	$avg = $pdu_story_Ttot{$story}{$op} / ($pdu_story_n{$story} * $op_count{$op});
	printf("%5d %9.1f %7d %s\n",
	       $pdu_story_Tmin{$story}{$op}, $avg, $pdu_story_Tmax{$story}{$op},
	       substr($bar10, 0, 5 * log(1+$avg) / log(10)));
	printf "    %-4s ", $op;
    }
    print "\n";
}

print "\n5.4 Narrative PDU History\n--------------------------\n\n";

@ticks = sort keys %pdu_narr;

if (0) {
    for ($j = 0; $j <= $#pdus; $j += 20) {
	$0 ="ak-lock: pdus($j)";
	$hdr  = '' . (' ' x length($time));
	for ($i = $j; $i < $j+20; ++$i) {
	    $hdr .= sprintf " %8s", $pdus[$i];
	    $pdu_state{$pdus[$i]} = ' ';
	}
	$hdr .= "\n";
	
	print $hdr;
	$n = 0;
	$last_time = 0;
	
	$n_start = (length @ticks > $narrative_lines + 100) ? 100 : 0;
	for $time (@ticks) {
	    if (!$compact && $last_time) {   # Print inactive usecs
		for (; $last_time < $time; $last_time += 0.000001) {
		    printf "  %.6f", $last_time;
		    for $pdu (@pdus) {
			printf " %-8s", $pdu_state{$pdu};
		    }
		    print "-\n";
		}
	    }
	    $last_time = $time + 0.000001;
	    
	    for ($i = $j; $i < $j+20; ++$i) {
		$pdu_act{$pdus[$i]} = '';
	    }
	    @evts = split /\n/, $pdu_narr{$time};
	    for $evt (@evts) {
		($thr, $pdu, $e) = split /\s+/, $evt;
		$pdu_act{$pdu} .= $e;
		$pdu_state{$pdu} = $pdu_state_tab{$e} || '.';
	    }
	    next if --$n_start > 0;
	    
	    print "  $time";
	    for ($i = $j; $i < $j+20; ++$i) {
		printf " %-8s", $pdu_act{$pdus[$i]} ? $pdu_act{$pdus[$i]} : $pdu_state{$pdus[$i]};
	    }
	    print "\n";
	    print $hdr if ++$n % 100 == 0;
	    last if $n > $narrative_lines;
	}
	print $hdr;
    }
} else {
    # Display PDUs using a "cache" of display slots. Any PDU that is
    # in F (free) state is eligible to give its slot. As secondary
    # criteria, LRU is used.

    @slots = ();      # Each slot holds ptr value of PDU
    @last_seen = ();  # Time value of last action for LRU purposes
    
    #$n_start = (length @ticks > $narrative_lines + 100) ? 100 : 0;

    $old_hdr = 0;
    $n = 0;
    $last_time = 0;
    for $time (@ticks) {
	$0 ="ak-lock: PDU $time $#slots";
	if (!$compact && $last_time) {   # Print inactive usecs
	    for (; $last_time < $time; $last_time += 0.000001) {
		printf "  %.6f", $last_time;
		for $pdu (@slots) {
		    printf " %-8s", $pdu_state{$pdu};
		}
		print "-\n";
	    }
	}
	$last_time = $time + 0.000001;
    
	for $pdu (@pdus) {
	    $pdu_act{$pdu} = '';
	}
	@evts = split /\n/, $pdu_narr{$time};
	for $evt (@evts) {
	    ($thr, $pdu, $e) = split /\s+/, $evt;
	    $pdu_act{$pdu} .= $e;
	    $pdu_state{$pdu} = $pdu_state_tab{$e} || '.';
	}
	
	for $pdu (@pdus) {
	    next if $pdu_state{$pdu} eq ' ' || $pdu_state{$pdu} eq '';
	    next if $pdu_slot{$pdu} && $slots[$pdu_slot{$pdu}] eq $pdu;   # We still have old slot
	    # Identify empty slots
	    %empties = ();
	    for ($i = 0; $i <= $#slots; ++$i) {
		$empties{$i} = $last_seen[$i] if $slots[$i] eq '' || $pdu_state{$slots[$i]} eq ' ';
	    }
	    @empty_slots = sort { $empties{$a} <=> $empties{$b} } keys %empties;  # LRU
	    if (defined $empty_slots[0]) {
		$slots[$empty_slots[0]] = $pdu;
		$pdu_slot{$pdu} = $empty_slots[0];
		#warn "$time Assigned PDU($pdu) slot($empty_slots[0])";
	    } else {  # No empty slot available. We simply need one more slot.
		push @slots, $pdu;
		$pdu_slot{$pdu} = $#slots;
		#warn "$time Assigned PDU($pdu) slot($#slots) due to no empty slots";
		#for $pdu (@slots) { warn "  $pdu: pdu_state($pdu_state{$pdu})"; }
	    }
	}

	$cols = $max_cols;
	$hdr  = ' ' . (' ' x length($time));
	for $pdu (@slots) {
	    $hdr .= sprintf " %8s", $pdu;
	    last if !--$cols;
	}
	print "$hdr ($#slots)\n" if $hdr ne $old_hdr;
	$old_hdr = $hdr;
	
	#next if --$n_start > 0;
	
	$line = '';
	$cols = $#slots < $max_cols-1 ? $#slots : $max_cols-1;
	for ($i = 0; $i <= $cols; ++$i) {
	    $pdu = $slots[$i];
	    $line .= sprintf " %-8s", $pdu_act{$pdu} ? $pdu_act{$pdu} : $pdu_state{$pdu};
	    $last_seen[$i] = $time if $pdu_act{$pdu};
	}
	$line .= "\n";
	print "  $time$line" if !$compact || $line ne $prev_line;
	$prev_line = $line;
	#print $hdr if ++$n % 100 == 0;
	#last if $n > $narrative_lines;
    }
    print $hdr;
}

$0 ="ak-lock: PDUs done";

print <<LEGEND;

  Legend: B=choose_be, C=contend lock, D=dequeue, E=enqueue, f=clean,
          H=hk_process, h=next_hk, L=lock, l=lock after contend,
          P=fe_populate, p=fe_pop2, U=unlock, .=no relevant activity *=new, ==free

  Final slots: $#slots
LEGEND
    ;

print "\n6 I/O Objects\n===================\n\n";

print "\n6.1 DSIO lock by reason taken\n-------------------------------\n\n";
print "  Reason                           N (log10 bars)\n";

for $reason (sort keys %dsio_lock_reason) {
    $n = $dsio_lock_reason{$reason};
    printf(" %30s %7d %-25s\n", $reason, $n, substr($bar5, 0, 5 * log($n) / log(10)));
}

print "\n6.2 DSQIO lock by reason taken\n-------------------------------\n\n";
print "  Reason                           N (log10 bars)\n";

for $reason (sort keys %dsqio_lock_reason) {
    $n = $dsqio_lock_reason{$reason};
    printf(" %30s %7d %-25s\n", $reason, $n, substr($bar5, 0, 5 * log($n) / log(10)));
}

print "\n7 Other Metrics\n===============\n\n";

print "\n7.1 Garbage Collects\n--------------------\n\n";

print "  Duration  N (log10 bars)\n";
$tot = 0;
for $d (sort { $a <=> $b } keys %gc_duration) {
    printf "  %4s %6d %s\n", $d, $gc_duration{$d}, substr($bar10, 0,  5 * log(1+$gc_duration{$d}) / log(10));
    $tot += $act{$thr};
}

print "  Total $tot garbage collects\n";

print "\n7.2 Polls\n---------\n\n";

$i = 0;
for $poll (sort keys %poll_ok) {
    ++$i;
    print "\n7.2.$i POLL_OK $poll\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
    
    $tot = 0;
    print "  Events  N_occur (log10 bars)\n";
    for $n (sort { $a <=> $b } keys %{$poll_ok{$poll}}) {
	printf "  %4s %6d %s\n", $n, $poll_ok{$poll}{$n}, substr($bar10, 0,  5 * log(1+$poll_ok{$poll}{$n}) / log(10));;
	$tot += $poll_ok{$poll}{$n};
    }
    print "  Total $tot polls\n";
}

### Final report

print "\n9 Concluding Remarks\n====================\n";

$ops_sec = int($tot * 1000000 / $t_diff);

print <<REPORT;

  Total lines analyzed: $tot
  Time covered:         $t_diff usec
  Activity rate:        $ops_sec lines/sec
  Date:                 $yyyymmdd
  First time:           $first_time
  Last time:            $time

END OF REPORT
REPORT
    ;

__END__
