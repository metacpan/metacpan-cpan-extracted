#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use JSON::MaybeXS qw/ JSON /;
use Data::Dumper;

my $pretty = 0;
if ($ENV{JSON_PRETTY}) { $pretty = 1; }

my %d_t_fmt = ();
my %d_fmt = ();
my %t_fmt = ();
my %r_fmt = ();
my %months = ();
my %months_abbr = ();
my %days = ();
my %days_abbr = ();
my %am_pm = ();
my %era = ();
my %era_d_fmt = ();
my %era_d_t_fmt = ();
my %era_t_fmt = ();
my %alt_digits = ();
my %date_fmt = ();

my $dir = shift; $dir //= "/usr/share/i18n/locales";

opendir my $dh, $dir or die "Could not open $dir: $!";

foreach my $file (grep -f "$dir/$_", readdir $dh) {
    open my $fh, '<', "$dir/$file" or die "Could not open $dir/$file: $!";

    $_ = do { local $/; readline $fh; };
    close $fh;

    my ($comment) = /^comment_char\s+(\S+)$/m;
    my ($escape) = /^escape_char\s+(\S+)$/m;

    # remove comments
    if (defined $comment) {
        s/^$comment.*$//gm;
        my @lines = split /\n/;
        foreach my $line (@lines) {
            $line =~ s/^[^"]*("[^"]*"[^"]*;?)*\K[\t ]*$comment.*$escape/$escape/ if defined $escape;
            $line =~ s/^[^"]*("[^"]*"[^"]*;?)*\K[\t ]*$comment.*[^$escape]// if defined $escape;
            $line =~ s/^[^"]*("[^"]*"[^"]*;?)*\K[\t ]*$comment.*// if not defined $escape;
        }
        $_ = join "\n", @lines;
        #s/;\K\s*$comment\s?\S+[\t ]*//g;
        s/$comment\s*$//gm;
    }

    # remove escapes
    s/$escape\n[\t ]*//g if defined $escape;
    s/\n\n+/\n\n/g;

    my ($d_t_fmt)     = /^d_t_fmt\s+"(.*)"[\t ]*$/m;
    my ($d_fmt)       = /^d_fmt\s+"(.*)"[\t ]*$/m;
    my ($t_fmt)       = /^t_fmt\s+"(.*)"[\t ]*$/m;
    my ($r_fmt)       = /^t_fmt_ampm\s+"(.*)"[\t ]*$/m;
    my ($abday)       = /^abday\s+(".*")[\t ]*$/m;
    my ($day)         = /^day\s+(".*")[\t ]*$/m;
    my ($abmon)       = /^abmon\s+(".*")[\t ]*$/m;
    my ($mon)         = /^mon\s+(".*")[\t ]*$/m;
    my ($am_pm)       = /^am_pm\s+(".*")[\t ]*$/m;
    my ($era)         = /^era\s+(".*")[\t ]*$/m;
    my ($era_d_t_fmt) = /^era_d_t_fmt\s+"(.*)"[\t ]*$/m;
    my ($era_d_fmt)   = /^era_d_fmt\s+"(.*)"[\t ]*$/m;
    my ($era_t_fmt)   = /^era_t_fmt\s+"(.*)"[\t ]*$/m;
    my ($date_fmt)    = /^date_fmt\s+"(.*)"[\t ]*$/m;
    my ($alt_digits)  = /^alt_digits\s+(".*")[\t ]*$/m;

    if (defined $abday) {
        my @abdays = map { decode_fmt($_) } map { /"([^"]+)"/ } split /;/, $abday;
        $days_abbr{$file} = \@abdays;
    }
    if (defined $day) {
        my @days = map { decode_fmt($_) } map { /"([^"]+)"/ } split /;/, $day;
        $days{$file} = \@days;
    }
    if (defined $abmon) {
        my @abmons = map { decode_fmt($_) } map { /"([^"]+)"/ } split /;/, $abmon;
        $months_abbr{$file} = \@abmons;
    }
    if (defined $mon) {
        my @mons = map { decode_fmt($_) } map { /"([^"]+)"/ } split /;/, $mon;
        $months{$file} = \@mons;
    }
    if (defined $am_pm) {
        my @am_pms = map { decode_fmt($_) } map { /"([^"]+)"/ } split /;/, $am_pm;
        $am_pm{$file} = \@am_pms;
    } else {
        #$am_pm{$file} = [qw/ AM PM /];
    }
    if (defined $era) {
        my @eras = map { decode_fmt($_) } map { /"([^"]+)"/ } split /;/, $era;
        $era{$file} = \@eras;
    }
    if (defined $alt_digits) {
        my @alt_digits = map { decode_fmt($_) } map { /"([^"]+)"/ } split /;/, $alt_digits;
        $alt_digits{$file} = \@alt_digits;
    }

    $d_t_fmt{$file} = decode_fmt($d_t_fmt) if length $d_t_fmt;
    $d_fmt{$file} = decode_fmt($d_fmt) if length $d_fmt;
    $t_fmt{$file} = decode_fmt($t_fmt) if length $t_fmt;
    if (length $r_fmt) {
        $r_fmt{$file} = decode_fmt($r_fmt);
    } else {
        $r_fmt{$file} = "%I:%M:%S %p" if defined $d_t_fmt{$file} and $d_t_fmt{$file} =~ /%r/;
        $r_fmt{$file} = "%I:%M:%S %p" if defined $t_fmt{$file} and $t_fmt{$file} =~ /%r/;
    }
    $era_d_t_fmt{$file} = decode_fmt($era_d_t_fmt) if length $era_d_t_fmt;
    $era_d_fmt{$file} = decode_fmt($era_d_fmt) if length $era_d_fmt;
    $era_t_fmt{$file} = decode_fmt($era_t_fmt) if length $era_t_fmt;
    $date_fmt{$file} = decode_fmt($date_fmt) if length $date_fmt;
}

sub decode_fmt {
    my $fmt = shift;
    $fmt =~ s/<U([0-9A-Fa-f]+)>/chr hex $1/ge;

    return $fmt;
}

my $comment = sprintf "# format db generated on %s from %s.\n", "".localtime, $dir;
print JSON->new->utf8(1)->pretty($pretty)->canonical(1)->encode({ comment => $comment, d_t_fmt => \%d_t_fmt, d_fmt => \%d_fmt, t_fmt => \%t_fmt, days => \%days, days_abbr => \%days_abbr, months => \%months, months_abbr => \%months_abbr, am_pm => \%am_pm, r_fmt => \%r_fmt, era => \%era, era_d_t_fmt => \%era_d_t_fmt, era_d_fmt => \%era_d_fmt, era_t_fmt => \%era_t_fmt, date_fmt => \%date_fmt, alt_digits => \%alt_digits, });
