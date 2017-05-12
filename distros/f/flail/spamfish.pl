#!/usr/bin/perl
##
# spamfish.pl - fish a mailbox for patterns based on autofile_config.pl
#
# Copyright (C) 2000-2006 by Sean Levy <snl@cluefactory>
# All Rights Reserved.
#
# Time-stamp: <2008-03-25 18:48:14 snl@cluefactory.com>
#
# See POD at EOF, or invoke with -help -verbose
##
use strict;
use vars qw($P $VERSION $VERBOSE $QUIET $DEFAULTS $COPY_YEARS $AUTO_FILE);
use POSIX;
use Pod::Usage;
use Cwd;
use Mail::Folder;
use Mail::Folder::Mbox;

BEGIN {
    ($P) = reverse(split('/', $0));
    my $yyyy = 1900+(localtime(time))[5];
    ## XXX edit 2006
    $COPY_YEARS = sprintf(($yyyy == 2006) ? q{%d} : q{%d-%d}, 2006, $yyyy);
}

$DEFAULTS = {
    'config' => $ENV{'HOME'}."/.flail/autofile_config.pl",
    'folders' => $ENV{'HOME'}."/mail/folders",
    'touch' => $ENV{'HOME'}."/.spamfish.t",
};
$VERSION = '0.1.0';
$QUIET = 0;

## qchomp - trim leading and trailing whitespace and deal with quoted strings
##
sub qchomp {
    my $str = shift(@_);
    while ($str =~ /^\s*([\"\'])(.*)\1\s*$/) {
        $str = $2;
    }
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

## parse_argv - simplistic and effective CLA parser
##
sub parse_argv {
    my $args;
    if (@_ && (ref($_[0]) eq 'HASH')) {
        $args = shift(@_);
    } else {
        $args = {};
    }
    my @argv = @_;
    foreach my $arg (@argv) {
        $arg =~ s/^\s+//;
        $arg =~ s/\s+$//;
        next unless length $arg;
        if ($arg =~ /^(-{1,2}[^=]+?)[=](.*)$/) {
            my($k,$v) = ($1,qchomp($2));
            $k =~ s/^-+//;
            if ($k ne '_') {
                if (!exists($args->{$k}) || (ref($args->{$k}) !~ /^(ARRAY|HASH)$/)) {
                    $args->{$k} = $v;
                } elsif (ref($args->{$k}) eq 'HASH') {
                    my($kk,$vv) = split(/:/,$v,2);
                    $args->{$k}->{$kk} = $vv;
                } else {
                    push(@{$args->{$k}}, $v);
                }
            } else {
                $args->{$k} = [] unless defined $args->{$k};
                push(@{$args->{$k}}, $v);
            }
        } elsif ($arg =~ /^(-{1,2}.*)$/) {
            my $k = qchomp($1);
            $k =~ s/^-+//;
            if ($k ne '_') {
                ++$args->{$k};
            } else {
                usage(qq{Cannot have an option named underscore});
            }
        } else {
            $args->{'_'} = [] unless defined $args->{'_'};
            push(@{$args->{'_'}}, $arg);
        }
    }
    ## Shortcuts: -v = -verbose, -V = -verbosity, -n = noexec
    $args->{'verbose'} = $args->{'v'}
        if (defined($args->{'v'}) && !defined($args->{'verbose'}));
    $args->{'verbosity'} = $args->{'V'}
        if (defined($args->{'V'}) && !defined($args->{'verbosity'}));
    $args->{'quiet'} = $args->{'q'}
        if (defined($args->{'q'}) && !defined($args->{'quiet'}));
    if (exists($DEFAULTS->{' required opts'})) {
        my %req = %{$DEFAULTS->{' required opts'}};
        my @missing = (
            sort { $a cmp $b }
            grep { !exists($args->{$_}) }
            keys %req
        );
        usage(qq{missing required options: }.join(', ', @missing)) if @missing;
    }
    return $args;
}

## usage - dump a usage message and die
##
sub usage {
    my($msg) = @_;
    pod2usage(-verbose => 2)                    if $VERBOSE && !defined($msg);
    if (defined($msg)) {
        print STDERR "$P: $msg\n"               if defined $msg;
    } else {
        print STDERR "$P: fish for non-spam in a spam mailbox\n";
    }
    print STDERR "usage: $P [-options] [args]\n";
    print STDERR "       Standard options:\n";
    print STDERR "          -v|verbose      increment verbosity level\n";
    print STDERR "          -V|verbosity=n  set verbosity level to n\n";
    print STDERR "          -q|quiet        suppress all output save errors\n\n";
    print STDERR "          -help           print this brief message\n";
    print STDERR "          -copyright      print our version and copyright\n";
    print STDERR "          -license        print our modified BSD license\n\n";
    print STDERR "       To see the full documentation, try:\n\n";
    print STDERR "           \$ $P -help -verbose\n";
    exit(defined($msg)? 1:0);
}

## mumble - interstitial, random messages that should go somewhere
##
sub mumble {
    my($lvl,$msg) = @_;
    return unless $lvl <= $VERBOSE;
    print STDERR "[$P($lvl) $msg]\n";
}

## ts - return formatted timestamp
##
sub ts {
    my $when = shift(@_) || POSIX::ceil(time());
    my $fmt = shift(@_) || "%Y-%m-%d %H:%M:%S";
    return POSIX::strftime($fmt, localtime($when));
}

## copyright - print our version and copyright
##
sub copyright {
    print "$P version $VERSION\n";
    print "Copyright (C) $COPY_YEARS by attila <attila\@stalphonsos.com>.\n";
    print "All Rights Reserved.\n\n";
    print "This program is distributed under a BSD-style license; try\n";
    print "    \$ $P -license\n";
    print "to see the whole thing.  Be a good Netizen, support your local BSD Unix!\n";
    exit(0);
}

## license - print our modified BSD license
##
sub license {
    print <<__LiCENsE__;
$P version $VERSION
Copyright (C) $COPY_YEARS by attila <attila\@stalphonsos.com>.
All rights Reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

   1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
   2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
   3. Neither the name of the St.Alphonsos nor the names of its contributors
      may be used to endorse or promote products derived from this software
      without specific prior written permission. 

THIS SOFTWARE IS PROVIDED BY ST.ALPHONSOS AND CONTRIBUTORS ``AS IS''
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ST.ALPHONSOS OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
__LiCENsE__
    exit(0);
}

sub say { print "@_\n" if $VERBOSE; }

sub psychochomp {
    my $in = shift(@_);
    $in =~ s/^\s+//g;
    $in =~ s/\s+$//g;
    return $in;
}

# is this strictly RFC822 compliant?  what i want is to SQUISH all
# extraneous whitespace in an address wherever it might be.
sub addresschomp {
    my $in = shift(@_);
    $in =~ s/\n/ /g;
    $in =~ s/\r/ /g;
    $in =~ s/\s+/ /g;
    $in = psychochomp($in);
    return $in;
}

sub push_autofile_result {
    my($results,$tag,$foo,$k) = @_;
    my $flags = undef;
    ($k,$flags) = ($1,{ map { $_ => 1 } split(/,/, $2) })
        if ($k =~ /^(.*)\[([\w\.]+)\]$/);
    push(@$results, [ $tag, $foo, $k, $flags ]);
}

sub suss_autofile_by_headers {
    return unless defined($AUTO_FILE);
    my $h = shift(@_);
    my $args = shift(@_);
    my $no_mailer_daemon = (defined($args) && $args->{'nmd'}) ? 1 : 0;
    my @headers = (
        grep { $_ !~ /^[: ]/ }
        keys %$AUTO_FILE
    );
    my @results = ();
#+D     say "autofile_by_headers: @headers";
    foreach my $tag (@headers) {
        my $hash = $AUTO_FILE->{$tag};
        my @hdrs = split(/,/, $tag);
        foreach my $hdr (@hdrs) {
            my $n = $h->count($hdr);
            my $j = 0;
#+D             say "autofile: examining $n $hdr headers";
            while ($j < $n) {
                my $v = $h->get($hdr,$j);
                ++$j;
                $v = addresschomp($v);
                next if ($no_mailer_daemon && ($v =~ /MAILER-DAEMON\@/i));
                my @tmp = split(/,/, $v);
#+D                 say "autofile: $j/$n=$v";
                foreach my $foo (@tmp) {
                    $foo = addresschomp($foo);
                    study($foo); ### Maybe?
#+D                     say "autofile: studied $hdr=$foo";
                    foreach my $k (keys %$hash) {
                        my $re = $hash->{$k};
#+D                         say "autofile: $k: /$re/";
                        push_autofile_result(\@results,$hdr,$foo,$k)
                            if ($foo =~ /$re/i);
                    }
                }
            }
        }
    }
    return @results;
}

sub dump_autofile_results {
    my($fname,$msgno,@args) = @_;
    foreach my $auto (@args) {
        my($header,$value,$folder,$flags) = @$auto;
        my $flagstr = '';
        $flagstr = ' ('.join(',', sort { $a cmp $b } keys %$flags) . ')'
            if defined($flags);
        print "$fname:$msgno: $header=$value => $folder$flagstr\n";
    }
}

sub suss_autofile_by_content {
    return unless defined($AUTO_FILE);
#+D     say "autofile: args=@_\n";
    my $h = shift(@_);
    my $chash = $AUTO_FILE->{':Content'};
    return () unless defined($chash);
    my @results = ();
    my $body = $h->body();
    if (!defined($body)) {
        warn("<2>no body in $h\n");
        return ();
    }
    $body = join("\n", @$body) if ref($body) eq 'ARRAY';
    study($body);
    foreach my $k (keys %$chash) {
        my $re = $chash->{$k};
        if ($body =~ /$re/) {
            my $captured = [];
            foreach my $i (1 .. 9) {
                last unless defined(${$i});
                push(@$captured, ${$i});
            }
            $captured = undef unless @$captured > 0;
            push_autofile_result(\@results,':Content',$captured,$k);
        }
    }
    return @results;
}

##
## Main Program
##

MAIN: {
    my $args = parse_argv({'_' => []}, @ARGV);
    $VERBOSE = $args->{'verbosity'} || $args->{'verbose'} || 0;
    $QUIET = $args->{'quiet'} || 0;
    license()   if $args->{'license'};
    copyright() if $args->{'version'} || $args->{'copyright'};
    usage()     if $args->{'help'};
    my $cfg = $args->{'config'} || $DEFAULTS->{'config'};
    usage(qq{Need config file at least}) unless $cfg;
    usage(qq{Config "$cfg" does not exist}) unless (-f $cfg);
    my $fdir = $args->{'folders'} || $DEFAULTS->{'folders'};
    usage(qq{Folder dir "$fdir" not a directory}) unless (-d $fdir);
    $| = 1;
    do "$cfg";
    die(qq{$cfg: $@\n}) if $@;
    my @hdrs = keys(%{$::AUTO_FILE});
    my $nhead = scalar(@hdrs);
    warn "[$nhead headers in $cfg]\n" if $VERBOSE;
    my @boxes = map { ($_ =~ /^\d+$/)? "spam$_": "$_" } @{$args->{'_'}};
    if (!@boxes && $args->{'recent'}) {
        my $touchfile = $args->{'touch'} || $DEFAULTS->{'touch'};
        my $mtime = (stat($touchfile))[9] if (-f $touchfile);
        my $here = getcwd();
        chdir($fdir) or die(qq{$P: chdir($fdir): $!\n});
        @boxes = grep { $_ !~ /\.(bz2|gz)$/ } <spam*>;
        if (!$mtime) {
            print STDERR "[Doing all ".scalar(@boxes)." spamboxes]\n"
                if $VERBOSE;
        } else {
            my $nb = @boxes;
            @boxes = grep { (stat($_))[9] >= $mtime } @boxes;
            print STDERR "[Doing ".scalar(@boxes)." out of $nb total]\n"
                if $VERBOSE;
            exit(0) unless @boxes;
        }
        @boxes = sort { (stat($b))[9] <=> (stat($a))[9] } @boxes;
        chdir($here) or die(qq{$P: chdir($here): $!\n});
    } elsif (!@boxes && $args->{'all'}) {
        my $here = getcwd();
        chdir($fdir) or die(qq{$P: chdir($fdir): $!\n});
        @boxes = (
            sort { (stat($b))[9] <=> (stat($a))[9] }
            grep { (-f $_) && ($_ =~ /\d+$/) }
                <spam*>
        );
        chdir($here) or die(qq{$P: chdir($here): $!\n});
        print STDERR "[Doing all ".scalar(@boxes)." spamboxes]\n" if $VERBOSE;
    }
    my $npats = 0;
    $npats += scalar(keys(%{$AUTO_FILE->{$_}})) foreach (@hdrs);
    warn "[Processing ".scalar(@boxes).
        " boxes against $npats total patterns in $nhead headers]\n"
            if $VERBOSE;
    foreach my $box (@boxes) {
        if ((! -f $box) && (-f "$fdir/$box")) {
            $box = "$fdir/$box";
        }
        if (!(-f $box)) {
            warn(qq|Skipping "$box" - does not exist\n|);
            next;
        }
        my $ftype = 'AUTODETECT';
        ($ftype,$box) = ($1,$2) if ($box =~ /^(\w+):(.*)$/);
        my $folder = Mail::Folder->new($ftype,$box);
        if (!$folder) {
            warn(qq|Could not open $ftype "$box" - skipped\n|);
        } else {
            my $nmsgs = $folder->qty();
            my $fname = $folder->foldername();
            warn("[Processing $nmsgs messages in $fname]\n") if $VERBOSE;
            my $dots = 0;
            my @all_results = ();
            for (my $msgno = 1; $msgno <= $folder->qty; ++$msgno) {
                my $msg = $folder->get_message($msgno)
                    or die(qq{$box:$msgno: could not read!\n});
                my $hdr = $msg->head();
                my @auto = (
                    suss_autofile_by_headers($hdr,$args),
                    suss_autofile_by_content($msg,$args)
                );
                if (@auto) {
                    unless ($args->{'nodots'}) {
                        print STDERR "!";
                        ++$dots;
                    }
                    push(@all_results, [ $fname, $msgno, @auto ]);
                } elsif (!$args->{'nodots'}) {
                    print STDERR ".";
                    ++$dots;
                }
            }
            $folder->close();
            print STDERR "\n" if $dots;
            warn("[Found ".scalar(@all_results)." matches over $nmsgs messages in $fname]\n") if $VERBOSE;
            dump_autofile_results(@$_) foreach (@all_results);
        }
    }
    unless ($args->{'no-save'}) {
        my $touchfile = $args->{'touch'} || $DEFAULTS->{'touch'};
        open(TOUCH, "> $touchfile") or die(qq{$P: $touchfile: $!\n});
        print TOUCH ts()."\n";
        close(TOUCH);
    }
    exit(0);
}

__END__

=head1 NAME

spamfish - fish for non-spam in a spam mailbox

=head1 SYNOPSIS

  $ spamfish spam17

=head1 DESCRIPTION

Runs your C<autofile_config.pl> filters over the named mailboxes
to see if any messages that were classified as spam match your
regexp filters.  Quick way of finding false positives from the
command-line.

=head1 OPTIONS

=over 4

=item -verbose (or -v)

=item -verbosity=int (or -V=int)

The first form increments the verbosity level every time it is seen.
The second form sets the verbosity level to the integer specified.
Higher verbosity levels mean more output.

=item -quiet

Be quiet about everything but errors.

=item -help

Print a short usage message.  If you specify -verbose, you get this
man page.

=item -version (also -copyright)

=item -license

Print our version and copyright, or our license.

=back

=head1 VERSION HISTORY

B<Alice>: Well I must say I've never heard it that way before...

B<Caterpillar>: I know, I have improved it. 

Z<>

  0.1.0   dd mmm yy     attila  sample history line

=cut

##
# Local variables:
# mode: perl
# tab-width: 4
# perl-indent-level: 4
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# indent-tabs-mode: nil
# comment-column: 40
# End:
##
