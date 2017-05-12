##
# autofile.pl - auto-file messages in flail
#
# Time-stamp: <2006-07-02 12:16:38 attila@stalphonsos.com>
# $Id: autofile.pl,v 1.5 2006/07/13 17:59:11 attila Exp $
#
# Copyright (C) 2006 by Sean Levy <snl@cluefactory.com>.
# All Rights Reserved.
# This file is released under a BSD license.  See the LICENSE
# file that should've come with the flail distribution.
##
# This is the code I use to automatically file messages in my
# inbox based on regular expressions.  The $AUTO_FILE hashref
# (of which there is an example in autofile_config.pl) contains
# the data used by this code to decode what to do with messages.
#
# A message can match more than once, in which case it will
# be filed more than once.
#
# The two main entry points are autofile and automark, which
# are typically used like this from the flail command line:
#
#     map all { autofile() }
#
# I define an alias in dot.flailrc called autofile which does
# just this.  You can also see what autofile will do by using
# automark, which just marks matching messages instead of
# mv'ing them, but also spits out all of the matches for each
# message.
#
# This .pl file, along with a suitably tweaked autofile_config.pl
# should be installed somewhere in your @INC.  The sample
# dot.flailrc puts a directory called ~/.flail on the front of @INC
# if it exists, with the intention of it being a convenient
# place to stick exactly this kind of stuff.
##
use vars qw($AUTO_FILE);
sub say;

sub is_before {
    my($h,$d) = @_;
    my $dh = parsedate($h->get("Date"));
    my $dt = parsedate($d);
    return ($dh < $dt)? 1: 0;
}

sub is_after {
    my($h,$d) = @_;
    my $dh = parsedate($h->get("Date"));
    my $dt = parsedate($d);
    return ($dh >= $dt)? 1: 0;
}

sub is_about {
    my($h,$p) = @_;
    my $s = $h->get("Subject");
    return ($s =~ /$p/)? 1: 0;
}

sub is_from {
    my($h,$p) = @_;
    foreach my $x (qw(From Sender)) {
        my $f = $h->get($x);
        return 1 if $f =~ /$p/i;
    }
    return 0;
}

sub is_to {
    my($h,$p) = @_;
    foreach my $x (qw(To Cc Bcc)) {
        my $f = $h->get($x);
        return 1 if $f =~ /$p/i;
    }
    return 0;
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
    my @headers = (
        grep { $_ !~ /^[: ]/ }
        keys %$AUTO_FILE
    );
    my @results = ();
    say "autofile_by_headers: @headers";
    foreach my $tag (@headers) {
        my $hash = $AUTO_FILE->{$tag};
        my @hdrs = split(/,/, $tag);
        foreach my $hdr (@hdrs) {
            my $n = $h->count($hdr);
            my $j = 0;
            say "autofile: examining $n $hdr headers";
            while ($j < $n) {
                my $v = $h->get($hdr,$j);
                ++$j;
                $v = addresschomp($v);
                my @tmp = split(/,/, $v);
                say "autofile: $j/$n=$v";
                foreach my $foo (@tmp) {
                    $foo = addresschomp($foo);
                    study($foo); ### Maybe?
                    say "autofile: studied $hdr=$foo";
                    foreach my $k (keys %$hash) {
                        my $re = $hash->{$k};
                        say "autofile: $k: /$re/";
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
    foreach my $auto (@_) {
        my($header,$value,$folder,$flags) = @$auto;
        my $flagstr = '';
        $flagstr = ' ('.join(',', sort { $a cmp $b } keys %$flags) . ')'
            if defined($flags);
        print "autofile: $header = $value => $folder$flagstr\n";
    }
}

sub suss_autofile_by_content {
    return unless defined($AUTO_FILE);
    say "autofile: args=@_\n";
    my $h = shift(@_);
    my $chash = $AUTO_FILE->{':Content'};
    return () unless defined($chash);
    my @results = ();
    my $body = $h->body();
    if (!defined($body)) {
        warn("<2>no body in $h? trying $M\n");
        $body = $M->body() if defined($M);
        if (!defined($body)) {
            warn("<2>no body no how\n");
            return ();
        }
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

sub autofile {
    my $h = $H;
    my @auto = (
        suss_autofile_by_headers($H),
        suss_autofile_by_content($M)
    );
    return unless @auto > 0;
    my %filed = ();
    foreach my $af (@auto) {
        next unless defined($af); ## ??
        my($header,$value,$folder,$flags) = @$af;
        my $flagstr = '';
        $flagstr = ' ('.join(',', sort { $a cmp $b } keys %$flags) . ')'
            if defined($flags);
        say "autofile: $header = $value => $folder$flagstr";
        next unless defined($folder);
        my $to = $h->get("To");
        $to = addresschomp($to);
        my $subj = $h->get("Subject");
        $subj = psychochomp($subj);
        unless (defined($flags) && $flags->{'quiet'}) {
            if ($header ne ':Content') {
                print "[$N: $header:$value => $to: $subj => $folder$flagstr]\n";
            } else {
                print "[$N: Content Match: $to: $subj => $folder$flagstr]\n";
            }
        }
        flail_eval("mv $N $folder") unless $filed{$folder}; ## API needs work, man
        ++$filed{$folder};
    }
}

sub automark {
    my @auto = (
        suss_autofile_by_headers($H),
        suss_autofile_by_content($M),
    );
    return unless @auto > 0;
    flail_eval("mark $N");
    my $to = $H->get("To");
    $to = addresschomp($to);
    my $subj = $H->get("Subject");
    $subj = psychochomp($subj);
    foreach my $af (@auto) {
        next unless defined($af);
        my($header,$value,$folder,$flags) = @$af;
        unless (defined($flags) && $flags->{'quiet'}) {
            my $flagstr = '';
            $flagstr = ' ('.join(',', sort { $a cmp $b } keys %$flags) . ')'
                if defined($flags);
            if ($header ne ':Content') {
                print "[$N: Marked ($folder): $header:$value => $to: $subj$flagstr]\n";
            } else {
                print "[$N: Marked for content ($folder): $to: $subj$flagstr]\n";
            }
        }
    }
}

1;
__END__

# Local variables:
# mode: perl
# indent-tabs-mode: nil
# tab-width: 4
# perl-indent-level: 4
# End:
