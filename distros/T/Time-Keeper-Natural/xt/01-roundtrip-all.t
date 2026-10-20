#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural::Lexicon;

# Every locale: everything format_relative writes, in every width and both
# numerics, reads back; and every weekday pattern. About 700,000 asks.
my $anchor = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
local $Time::Keeper::CLOCK = $anchor;
my %by_unit = (year => 'years', quarter => 'months', month => 'months', week => 'weeks', day => 'days',
               hour => 'hours', minute => 'minutes', second => 'seconds');
my %FIXED = (zero => 0, one => 1, two => 2);
my ($asks, $locales, @failed) = (0, 0);

for my $loc (Time::Keeper::Locale->codes) {
    $locales++;
    my $lex = Time::Keeper::Natural::Lexicon->for($loc);
    my $v = $anchor->in_locale($loc);
    my @bad;
    for my $unit (sort keys %by_unit) {
        for my $count (-3 .. 3) {
            my $t = $v->plus($by_unit{$unit} => ($unit eq 'quarter' ? 3 * $count : $count));
            for my $style (qw(long short narrow)) {
                for my $numeric (qw(auto always)) {
                    $asks++;
                    my $s = $t->format_relative(to => $v, unit => $unit, style => $style, numeric => $numeric);
                    push @bad, "$unit $count $style $numeric: '$s'" unless grep { ($_->{field} || '') eq $unit && $_->{n} == $count } $lex->read($s);
                }
            }
        }
    }
    my @digits = Time::Keeper::Locale->digits($loc);
    for my $f (qw(mon tue wed thu fri sat sun)) {
        for my $w (qw(long short narrow)) {
            my $r = Time::Keeper::Locale->relative_names($loc, $f, $w);
            for my $k (keys %{ $r->{at} }) {
                $asks++;
                push @bad, "$f $w at $k '$r->{at}{$k}'" unless grep { ($_->{field} || '') eq $f && $_->{n} == $k } $lex->fixed($r->{at}{$k});
            }
            for my $dir ([future => 1], [past => -1]) {
                my ($d, $sign) = @$dir;
                for my $cat (keys %{ $r->{$d} }) {
                    my $p = $r->{$d}{$cat};
                    for my $c (1, 2, 3, 5, 21) {
                        $asks++;
                        if ($p =~ /\{0\}/) {
                            (my $s = $p) =~ s/\{0\}/join '', map { $digits[$_] } split m{}, $c/e;
                            push @bad, "$f $w $d $cat '$s'" unless grep { ($_->{field} || '') eq $f && $_->{n} == $sign * $c } $lex->counted($s);
                        }
                        else {
                            push @bad, "$f $w $d $cat '$p'" unless grep { ($_->{field} || '') eq $f && $_->{n} == $sign * $FIXED{$cat} } $lex->fixed($p);
                            last;
                        }
                    }
                }
            }
        }
    }
    if (@bad) {
        push @failed, $loc;
        diag("$loc: " . join('; ', @bad[0 .. ($#bad < 4 ? $#bad : 4)]));
    }
}

is(scalar @failed, 0, "$locales locales, $asks asks, " . scalar(@failed) . " locales with a miss") or diag(join ' ', @failed);
cmp_ok($asks, '>=', 1121 * 8 * 7 * 3 * 2, 'the count is what the promise says');

done_testing;
