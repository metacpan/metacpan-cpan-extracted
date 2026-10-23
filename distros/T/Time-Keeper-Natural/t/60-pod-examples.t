#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# Every example in the POD whose comment shows a value, run with the clock the
# POD names (Thursday 2026-10-15 09:00 in London, en-GB) and checked. An
# example whose comment is prose ("the year assumed", "dies: ...") is checked
# only for what the prose says: a value, or a death.
my $anchor = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London', locale => 'en-GB');
local $Time::Keeper::CLOCK = $anchor;
my $n = Time::Keeper::Natural->new(zone => 'Europe/London', locale => 'en-GB');

my (@checked, @bad);
for my $pm (map { $INC{$_} } 'Time/Keeper/Natural.pm', 'Time/Keeper/Natural/Match.pm') {
    open my $fh, '<:encoding(UTF-8)', $pm or die "$pm: $!";
    while (my $line = <$fh>) {
        next unless $line =~ /^\s+\$n((?:->in_locale\('[^']+'\)|->new\([^)]*\))*)->(parse|parse_date|parse_duration|parse_interval|match)\('([^']*)'\)(->value)?;\s*#\s*(.+?)\s*$/;
        my ($chain, $method, $text, $value, $comment) = ($1, $2, $3, $4, $5);
        my $p = $n;
        while ($chain =~ /->(in_locale|new)\(([^)]*)\)/g) {
            my ($m, $args) = ($1, $2);
            my @args = map { (my $s = $_) =~ s/^\s*'|'\s*$//g; $s } grep { /\S/ } split /\s*(?:,|=>)\s*/, $args;
            $p = $p->$m(@args);
        }
        my $got = eval {
            return join(' / ', $p->parse_interval($text)) || undef if $method eq 'parse_interval';
            my $v = $p->$method($text);
            $value || $method eq 'match' ? ($v ? $v->value : undef) : $v;
        };
        my $err = $@;
        push @checked, $text;
        if ($comment =~ /^(\d{4}-\d\d-\d\d(?:T[\d:.]+(?:[+-]\d\d:\d\d|Z))?|P[^\s,]+)(?:\s|,|$)/) {
            my $want = $1;
            push @bad, "$method('$text'): wanted $want, got " . (defined $got ? "$got" : "a death: $err") unless defined $got && "$got" eq $want;
        }
        elsif ($comment =~ /^dies\b/) {
            push @bad, "$method('$text'): wanted a death, got $got" if defined $got;
        }
        elsif ($comment =~ /^undef\b/) {
            push @bad, "$method('$text'): wanted undef, got $got" if defined $got;
        }
        else {
            push @bad, "$method('$text'): wanted a value ($comment), got a death: $err" unless defined $got || $comment =~ /\bdies\b/;
        }
    }
}
cmp_ok(scalar @checked, '>=', 40, 'the POD\'s examples: ' . scalar @checked);
ok(!@bad, 'every example reads as its comment says') or diag(join "\n", @bad);

done_testing;
