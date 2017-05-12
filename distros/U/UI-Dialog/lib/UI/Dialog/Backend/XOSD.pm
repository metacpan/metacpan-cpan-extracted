package UI::Dialog::Backend::XOSD;
###############################################################################
#  Copyright (C) 2004-2016  Kevin C. Krinke <kevin@krinke.ca>
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
###############################################################################
use 5.006;
use strict;
use warnings;
use Carp;
use UI::Dialog::Backend;
use FileHandle;

#: Ideas:
# - implement debugging code...
# - what about tail("/file")?
# - and my $fh = tail_pipe() ?
#   (or pipe_start(), pipe_print() and pipe_close())
# - now here's a kicker, what about a "valid fonts" list and a
# suitable mechanism to use (and cache) `xlsfonts` to determine
# the font to use. Once the decision is made the decision should
# simply be enforced rather than revalidated again and again.

BEGIN {
    use vars qw( $VERSION @ISA );
    @ISA = qw( UI::Dialog::Backend );
    $VERSION = '1.21';
}

sub new {
    my $proto = shift();
    my $class = ref($proto) || $proto;
    my $cfg = ((ref($_[0]) eq "HASH") ? $_[0] : (@_) ? { @_ } : {});
    my $self = {};
    bless($self, $class);
    $self->{'_opts'} = {};

	#: Dynamic path discovery...
	my $CFG_PATH = $cfg->{'PATH'};
	if ($CFG_PATH) {
		if (ref($CFG_PATH) eq "ARRAY") { $self->{'PATHS'} = $CFG_PATH; }
		elsif ($CFG_PATH =~ m!:!) { $self->{'PATHS'} = [ split(/:/,$CFG_PATH) ]; }
		elsif (-d $CFG_PATH) { $self->{'PATHS'} = [ $CFG_PATH ]; }
	} elsif ($ENV{'PATH'}) { $self->{'PATHS'} = [ split(/:/,$ENV{'PATH'}) ]; }
	else { $self->{'PATHS'} = ''; }

    $self->{'_opts'}->{'bin'} = $self->_find_bin('osd_cat');
    $self->{'_opts'}->{'tail'} = $self->_find_bin('tail');
    $self->{'_opts'}->{'kill'} = $self->_find_bin('kill');
    $self->{'_opts'}->{'pos'} = $cfg->{'pos'} || undef();
    $self->{'_opts'}->{'offset'} = $cfg->{'offset'} || 0;
    $self->{'_opts'}->{'align'} = $cfg->{'align'} || undef();
    $self->{'_opts'}->{'indent'} = $cfg->{'indent'} || 0;
    $self->{'_opts'}->{'font'} = $cfg->{'font'} || undef();
    $self->{'_opts'}->{'colour'} = $cfg->{'colour'} || $cfg->{'color'} || undef();
    $self->{'_opts'}->{'delay'} = $cfg->{'delay'} || 0;
    $self->{'_opts'}->{'lines'} = $cfg->{'lines'} || 0;
    $self->{'_opts'}->{'shadow'} = $cfg->{'shadow'} || 0;
    $self->{'_opts'}->{'age'} = $cfg->{'age'} || 0;
    $self->{'_opts'}->{'wait'} = ($cfg->{'wait'}) ? 1 : 0;
    $self->{'_opts'}->{'length'} = $cfg->{'wait'} || 40;
    $self->{'_opts'}->{'bar'} = $cfg->{'bar'} || "-";
    $self->{'_opts'}->{'mark'} = $cfg->{'mark'} || "|";
    unless (-x $self->{'_opts'}->{'bin'}) {
		croak("the osd_cat binary could not be found at: ".$self->{'_opts'}->{'bin'});
    }

    $self->{'_opts'}->{'trust-input'} =
      ( exists $cfg->{'trust-input'}
        && $cfg->{'trust-input'}==1
      ) ? 1 : 0;

    return($self);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Internal Methods
#:

my $SIG_CODE = {};
sub _del_display {
    my $CODE = $SIG_CODE->{$$};
    unless (not ref($CODE)) {
		delete($CODE->{'_DISPLAY'});
		$SIG_CODE->{$$} = "";
    }
}
sub _gen_opt_str {
    my $self = shift();
    my $args = shift();
    my $string = "";
    if ($args->{'pos'}) {
		my $pos = ($args->{'pos'} =~ /^top|middle|bottom$/i) ? lc($args->{'pos'}) : 'top';
		$string .= " --pos='".$pos."'";
    }
    if ($args->{'offset'}) {
		my $offset = ($args->{'offset'} =~ /^\d+$/) ? $args->{'offset'} : 0;
		$string .= " --offset='".$offset."'";
    }
    if ($args->{'align'}) {
		my $align = ($args->{'align'} =~ /^left|center|right$/i) ? lc($args->{'align'}) : 'left';
		$string .= " --align='".$align."'";
    }
    if ($args->{'indent'}) {
		my $indent = ($args->{'indent'} =~ /^\d+$/) ? $args->{'indent'} : 0;
		$string .= " --indent='".$indent."'";
    }
    if ($args->{'font'}) {
		my $font = $args->{'font'} || "-*-fixed-*-*-*-*-*-*-*-*-*-*-*-*";
		$string .= " --font='".$font."'";
    }
    if ($args->{'colour'}) {
		my $colour = $args->{'colour'} || "green";
		$string .= " --color='".$colour."'";
    }
    if ($args->{'delay'}) {
		my $delay = ($args->{'delay'} =~ /^\d+$/) ? $args->{'delay'} : 5;
		$string .= " --delay='".$delay."'";
    }
    if ($args->{'lines'}) {
		my $lines = ($args->{'lines'} =~ /^\d+$/) ? $args->{'lines'} : 5;
		$string .= " --lines='".$lines."'";
    }
    if ($args->{'shadow'}) {
		my $shadow = ($args->{'shadow'} =~ /^\d+$/) ? $args->{'shadow'} : 0;
		$string .= " --shadow='".$shadow."'";
    }
    if ($args->{'age'}) {
		my $age = ($args->{'age'} =~ /^\d+$/) ? $args->{'age'} : 0;
		$string .= " --age='".$age."'";
    }
    if ($args->{'wait'}) {
		$string .= " --wait";
    }
    $self->_debug("xosd: ".$string,3);
    return($string||" ");
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Public Methods
#:

sub line {
    my $self = shift();
    my $args = $self->_merge_attrs(@_);
    my $opts = $self->_gen_opt_str($args);
    if (open(XOSD,"| ".$self->{'_opts'}->{'bin'}.$opts." -")) {
		print XOSD ($args->{'text'}||'')."\n";
		close(XOSD);
    } else {
		croak("failed to open osd_cat output pipe!");
    }
}

sub file {
    my $self = shift();
    my $args = $self->_merge_attrs(@_);
    my $opts = $self->_gen_opt_str($args);
    if (-r $args->{'file'}) {
		if (open(FILE,"<".$args->{'file'})) {
			local $/;
			my $text = <FILE>;
			close(FILE);
			$text =~ s!\t!    !g;
			if (open(XOSD,"| ".$self->{'_opts'}->{'bin'}.$opts." -")) {
				print XOSD ($text||'')."\n";
				close(XOSD);
			} else {
				croak("failed to open osd_cat output pipe!");
			}
		}
    }
}

sub gauge {
    my $self = shift();
    my $args = $self->_merge_attrs(@_);
    my $opts = $self->_gen_opt_str($args);
    my $length = $args->{'length'} || 40;
    my $bar = ($args->{'bar'} || "-") x $length;
    my $percent = $args->{'percent'} || '0';
    $percent = (($percent <= 100 && $percent >= 0) ? $percent : 0 );
    my $perc = int((($length / 100) * $percent));
    substr($bar,($perc||0),1,($args->{'mark'}||"|"));
    my $text = $args->{'text'} ? $args->{'text'}."\n" : '';
    $text .= $percent."% ".$bar."\n";
    if (open(XOSD,"| ".$self->{'_opts'}->{'bin'}.$opts." -")) {
		print XOSD $text;
		close(XOSD);
    } else {
		croak("failed to open osd_cat output pipe!");
    }
}

sub display_start {
    my $self = shift();
    my $args = $self->_merge_attrs(@_);
    my $opts = $self->_gen_opt_str($args);
    $self->{'_DISPLAY'} ||= {};
    $self->{'_DISPLAY'}->{'ARGS'} = $args;
    return(0) if defined $self->{'_DISPLAY'}->{'FH'};
    my $command = $self->{'_opts'}->{'bin'}.$opts." -";
    $self->{'_DISPLAY'}->{'FH'} = new FileHandle;
    $self->{'_DISPLAY'}->{'FH'}->open("| $command");
    my $rv = $? >> 8;
    $self->{'_DISPLAY'}->{'FH'}->autoflush(1);
    my $this_rv;
    if ($rv && $rv >= 1) { $this_rv = 0; }
    else { $this_rv = 1; }
    return($this_rv);
}
sub display_text {
    my $self = shift();
    my $mesg;
    if (@_ > 1) { $mesg = join("\n",@_); }
    elsif (ref($_[0]) eq "ARRAY") { $mesg = join("\n",@{$_[0]}); }
    else { $mesg = $_[0] || return(0); }
    return(0) unless $self->{'_DISPLAY'}->{'FH'};
    my $fh = $self->{'_DISPLAY'}->{'FH'};
    $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
    print $fh $mesg."\n";
    return(((defined $self->{'_DISPLAY'}->{'FH'}) ? 1 : 0));
}
sub display_gauge {
    my $self = $_[0];
    return(0) unless $self->{'_DISPLAY'}->{'FH'};
    my $args = $self->_merge_attrs();
    my $length = $args->{'length'} || 40;
    my $bar = ($args->{'bar'} || "-") x $length;
    my $percent = $_[1] || 0;
    $percent = (($percent <= 100 && $percent >= 0) ? $percent : 0 );
    my $perc = int((($length / 100) * $percent));
    substr($bar,($perc||0),1,($args->{'mark'}||"|"));
    my $text = $_[2] ? $_[2]."\n" : '';
    $text .= $percent."% ".$bar."\n";
    my $fh = $self->{'_DISPLAY'}->{'FH'};
    $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
    print $fh $text;
    return(((defined $self->{'_DISPLAY'}->{'FH'}) ? 1 : 0));
}
sub display_stop {
    my $self = shift();
    return(0) unless $self->{'_DISPLAY'}->{'FH'};
    my $args = $self->{'_DISPLAY'}->{'ARGS'};
    my $fh = $self->{'_DISPLAY'}->{'FH'};
    $SIG_CODE->{$$} = $self; local $SIG{'PIPE'} = \&_del_gauge;
    $self->{'_DISPLAY'}->{'FH'}->close();
    delete($self->{'_DISPLAY'}->{'FH'});
    delete($self->{'_DISPLAY'}->{'ARGS'});
    delete($self->{'_DISPLAY'}->{'PERCENT'});
    delete($self->{'_DISPLAY'});
    return(1);
}

# #$d->tail( file => "/tmp/xosdtail.log", delay => '3' );
# sub tail {
#     my $self = shift();
#     my $args = $self->_merge_attrs(@_);
#     my $opts = $self->_gen_opt_str($args);
#     if (-r $args->{'file'}) {
# 	my $tail_cmnd = $self->{'_opts'}->{'tail'}.' -f '.$args->{'file'};
# 	system($tail_cmnd." | ".$self->{'_opts'}->{'bin'}.$opts." -");
#     } else {
# 	$self->line( @_, text => "couldn't open file: ".($args->{'file'}||'NULL') );
#     }
# }

# sub tailbg {
#     my $self = shift();
#     my $args = $self->_merge_attrs(@_);
#     my $opts = $self->_gen_opt_str($args);
#     if (-r $args->{'file'}) {
# 	my $tail_cmnd = $self->{'_opts'}->{'tail'}.' -f '.$args->{'file'};
# 	my $xosd_cmnd = $self->{'_opts'}->{'bin'}.$opts." -";
# #	system($tail_cmnd." | ".$self->{'_opts'}->{'bin'}.$opts." - &");
# #	$self->{'forkpid'} = $self->command_forked($tail_cmnd." | ".$self->{'_opts'}->{'bin'}.$opts." -");
# #	$self->{'forkpid'} = $self->command_forked($self->{'_opts'}->{'tail'},' -f '.$args->{'file'}. " | ".$self->{'_opts'}->{'bin'}.$opts." -");
# 	$self->{'forkpid'} = $self->tailbg_forked($tail_cmnd,$xosd_cmnd);
# 	print "pid: ".$self->{'forkpid'}."\n";
# 	return(1) if $self->{'forkpid'};
# 	return(0);
#     } else {
# 	$self->line( @_, text => "couldn't open file: ".($args->{'file'}||'NULL') );
#     }
# }


# sub command_forked {
#     my $self = shift();
#     if (my $pid = fork()) { return($pid); }
#     else { exec(@_); }
# }

# sub tailbg_forked {
#     my $self = shift();
#     my $tail = shift();
#     my $osdc = shift();
#     if (my $pid = fork()) { return($pid); }
#     else {
# 	# here we open the tail and read
# 	# while reading, print to an open osd_cat
# 	my $TSIGP = $SIG{'PIPE'};
# 	$SIG{'PIPE'} = "IGNORE";
# 	if (open(TAIL,$tail." |")) {
# 	    unless (open(OSDC,"| ".$osdc)) {
# 		close(TAIL);
# 		return();
# 	    }
# 	    my $TP = $|;
# 	    $| = 1;
# 	    while (my $line = <TAIL>) {
# 		print OSDC $line;
# 	    }
# 	    $| = $TP;
# 	    close(OSDC);
# 	    close(TAIL);
# 	}
# 	$SIG{'PIPE'} = $TSIGP;
#     }
# }

# sub tailbg_end {
#     my $self = shift();
#     my $args = $self->_merge_attrs(@_);
#     if ($self->{'forkpid'}) {
# 	print "pid: ".$self->{'forkpid'}."\n";
# 	if (kill(15,$self->{'forkpid'})) {
# 	    print "killed: ".$self->{'forkpid'}."\n";
# 	} else {
# 	    print "maimed: ".$self->{'forkpid'}."\n";
# 	}
#     }
# }

1;
