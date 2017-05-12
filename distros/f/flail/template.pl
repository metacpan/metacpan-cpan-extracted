#!/usr/bin/perl
##
# filename - brief description
#
# copyright (C) 1997-2000 by attila <attila@stalphonsos.com>.
# all rights reserved.
#
# Copyright (C) 2000-2006 by Sean Levy <snl@cluefactory.
# All Rights Reserved.
#
# Time-stamp: <2006-12-01 14:57:30 attila@stalphonsos.com>
# $Id$
#
# author: Sean Levy <snl@cluefactory.com> aka attila <attila@stalphonsos.com>
#
# See POD at EOF, or invoke with -help -verbose
##
use strict;
use vars qw($P $VERSION $VERBOSE $QUIET $DEFAULTS $COPY_YEARS);
use POSIX;
use Pod::Usage;

BEGIN {
    ($P) = reverse(split('/', $0));
    my $yyyy = 1900+(localtime(time))[5];
    ## XXX edit 2006
    $COPY_YEARS = sprintf(($yyyy == 2006) ? q{%d} : q{%d-%d}, 2006, $yyyy);
}

$DEFAULTS = {
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
        print STDERR "$P: purpose of $P\n";
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
    ## ...
    exit(0);
}

__END__

=head1 NAME

name of program - one-line summary

=head1 SYNOPSIS

usage summary

=head1 DESCRIPTION

description of program

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
