#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural::Lexicon;

my $X = 'Time::Keeper::Natural::Lexicon';
my $L = 'Time::Keeper::Locale';
my @FIELDS = qw(year quarter month week day hour minute second mon tue wed thu fri sat sun);
my %FIXED = (zero => 0, one => 1, two => 2);
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}
sub first_of { my ($list, %want) = @_; for my $m (@$list) { return $m unless grep { !defined $m->{$_} || $m->{$_} ne $want{$_} } keys %want } return undef }

# Every at string and every pattern of eight locales reads back as itself.
for my $loc (qw(en fr de ru ar ja zh he)) {
    my $lex = $X->for($loc);
    isa_ok($lex, $X, "$loc");
    is($lex->code, $loc, "$loc: its code");
    my @digits = $L->digits($loc);
    my (@bad, $asks);
    for my $f (@FIELDS) {
        for my $w (qw(long short narrow)) {
            my $r = $L->relative_names($loc, $f, $w);
            for my $k (keys %{ $r->{at} }) {
                $asks++;
                push @bad, "$f $w at $k '$r->{at}{$k}'" unless first_of([ $lex->fixed($r->{at}{$k}) ], field => $f, n => $k);
            }
            for my $dir ([future => 1], [past => -1]) {
                my ($d, $sign) = @$dir;
                for my $cat (sort keys %{ $r->{$d} }) {
                    my $p = $r->{$d}{$cat};
                    if ($p =~ /\{0\}/) {
                        for my $c (0, 1, 2, 3, 5, 11, 21) {
                            $asks++;
                            (my $s = $p) =~ s/\{0\}/join '', map { $digits[$_] } split m{}, $c/e;
                            push @bad, "$f $w $d $cat '$s'" unless first_of([ $lex->counted($s) ], field => $f, n => $sign * $c, count => $c);
                        }
                    }
                    else {
                        $asks++;
                        push @bad, "$f $w $d $cat '$p' (no {0})" unless first_of([ $lex->fixed($p) ], field => $f, n => $sign * $FIXED{$cat});
                    }
                }
            }
        }
    }
    ok(!@bad, "$loc: every at string and pattern reads back ($asks asks)") or diag(join "\n", @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
}

# The plan's surface.
{
    my $fr = $X->for('fr');
    is_deeply((first_of([ $fr->fixed('après-demain') ], field => 'day') || {}), { field => 'day', n => 2, width => 'long' }, 'après-demain');
    is_deeply((first_of([ $fr->fixed('mardi prochain') ], field => 'tue') || {}), { field => 'tue', n => 1, width => 'long' }, 'mardi prochain');
    is_deeply((first_of([ $fr->fixed('mar prochain') ], field => 'tue') || {})->{width}, 'short', 'mar. prochain, the dot not needed');
    my ($m) = $fr->counted('dans 3 semaines');
    is_deeply([ @{$m}{qw(field n count direction category)} ], [ 'week', 3, 3, 1, 'other' ], 'dans 3 semaines');
    ($m) = $fr->counted('il y a 21 jours');
    is_deeply([ @{$m}{qw(field n count)} ], [ 'day', -21, 21 ], 'il y a 21 jours');
    ($m) = $fr->counted('il y a 1 jour');
    is_deeply([ @{$m}{qw(n category)} ], [ -1, 'one' ], 'the one pattern');
    ok(!$fr->counted('dans 3 fortnights'), 'a unit it has not');
    ok(!$fr->fixed('xyzzy'), 'a word it has not');
    ok(!$fr->read('xyzzy'), 'and read agrees');
}

# Quirks.
{
    my $ar = $X->for('ar');
    my ($m) = $ar->fixed('خلال يومين');
    is_deeply([ @{$m}{qw(field n count category)} ], [ 'day', 2, 2, 'two' ], 'Arabic dual: a fixed phrase with count 2');
    ($m) = $ar->fixed('قبل يوم واحد');
    is_deeply([ @{$m}{qw(field n)} ], [ 'day', -1 ], 'and the one');
    ok(first_of([ $ar->counted('خلال 3 أيام') ], field => 'day', n => 3), 'Arabic with ASCII digits');
    my $eg = $X->for('ar-EG');
    is($eg->ascii_digits('١٥'), '15', 'ar-EG digits to ASCII');
    is($eg->ascii_digits('15'), '15', 'ASCII left alone');
    ok(first_of([ $eg->counted('قبل ٣ أيام') ], field => 'day', n => -3), 'ar-EG with its own digits');
    ok(first_of([ $eg->counted('قبل 3 أيام') ], field => 'day', n => -3), 'and with ASCII');
    my $he = $X->for('he');
    ok(first_of([ $he->counted('בעוד יומיים (2)') ], field => 'day', n => 2), 'Hebrew, the number in brackets');
    ok(first_of([ $he->fixed('בעוד יומיים') ], field => 'day', n => 2), 'and without them');
    my $ja = $X->for('ja');
    is($ja->spaceless, 1, 'Japanese is spaceless');
    is($X->for('en')->spaceless, 0, 'English is not');
    ok(first_of([ $ja->counted('3 日後') ], field => 'day', n => 3), 'as Time::Keeper writes it');
    ok(first_of([ $ja->counted('3日後') ], field => 'day', n => 3), 'and as people type it');
    ok(first_of([ $ja->fixed('来週の火曜日') ], field => 'tue', n => 1), 'a weekday phrase with the day name inside');
    my $fr = $X->for('fr');
    ok(first_of([ $fr->fixed("aujourd’hui") ], field => 'day', n => 0), 'the typographic apostrophe');
    ok(first_of([ $fr->fixed("aujourd'hui") ], field => 'day', n => 0), 'and the plain one');
    ok(first_of([ $fr->fixed('Demain') ], field => 'day', n => 1), 'a capital');
    ok(first_of([ $fr->fixed("DEMAIN") ], field => 'day', n => 1), 'all capitals');
    my $en = $X->for('en');
    ok(first_of([ $en->counted('in  3   days') ], field => 'day', n => 3), 'spaces collapsed');
    ok(first_of([ $en->counted(" in 3 days\n") ], field => 'day', n => 3), 'and trimmed');
    ok(first_of([ $en->counted('in 1 days') ], field => 'day', n => 1, category => 'other'), 'the number wins over the category');
    ok(first_of([ $en->counted('in 2 wk') ], field => 'week', n => 2, width => 'short'), 'wk without its dot');
    ok(first_of([ $en->counted('in 2 wk.') ], field => 'week', n => 2), 'and with it');
    ok(first_of([ $en->counted('3d ago') ], field => 'day', n => -3, width => 'narrow'), 'narrow');
    ok(!$en->counted('in days'), 'no number is no match');
    ok(!$en->counted('in x days'), 'nor a word that is not one');
    ok(!$en->counted('in 3'), 'nor a number alone');
    ok(!$en->counted('xyzzy 3 days ago'), 'nor a word before the pattern');
    ok(!$en->counted('3 days ago xyzzy'), 'nor one after it');
    is($en->number('21'), 21, 'number');
    is($en->number(' 7 '), 7, 'padded');
    is($en->number('seven'), 7, 'a number word');
    is($en->number('Twenty-One'), 21, 'with capitals and a hyphen');
    is($en->number('hundred'), undef, 'but not past 99');
    is($en->number('-3'), undef, 'no sign');
    ok(first_of([ $en->fixed('the day after tomorrow') ], field => 'day', n => 2) || !exists $L->relative_names('en', 'day')->{at}{2}, 'English has no day after tomorrow in CLDR 48, or reads it');
}

# Names and periods.
{
    my $en = $X->for('en');
    is_deeply([ $en->fixed('Tuesday') ], [ { weekday => 2 } ], 'Tuesday');
    is_deeply([ $en->fixed('tue') ], [ { weekday => 2 } ], 'Tue');
    is_deeply([ $en->fixed('Tu') ], [ { weekday => 2 } ], 'Tu, the short width');
    is_deeply([ $en->fixed('October') ], [ { month => 10 } ], 'October');
    is_deeply([ $en->fixed('oct') ], [ { month => 10 } ], 'Oct');
    is_deeply([ $en->fixed('noon') ], [ { period => 'noon' } ], 'noon');
    is_deeply([ $en->fixed('in the afternoon') ], [ { period => 'afternoon1' } ], 'in the afternoon');
    is_deeply([ $en->fixed('pm') ], [ { period => 'pm' } ], 'pm');
    my $fr = $X->for('fr');
    is_deeply([ $fr->fixed('mar') ], [ { weekday => 2 } ], 'fr mar. is Tuesday');
    is_deeply([ $fr->fixed('mars') ], [ { month => 3 } ], 'and mars is March');
    my $ties = $fr->ties;
    ok($ties->{'du matin'}, 'du matin is a tie in French') or diag(join ',', sort keys %$ties);
    is_deeply([ sort map { $_->{period} } @{ $ties->{'du matin'} || [] } ], [ 'morning1', 'night1' ], 'the morning and the night');
    ok(!$X->for('en')->ties->{noon}, 'noon is not a tie');
}

# Duration words.
{
    my $en = $X->for('en');
    my ($m) = $en->unit('3 hours');
    is_deeply([ @{$m}{qw(unit n count category width)} ], [ 'hour', 3, 3, 'other', 'long' ], '3 hours');
    ($m) = $en->unit('1 hr');
    is_deeply([ @{$m}{qw(unit n width)} ], [ 'hour', 1, 'short' ], '1 hr');
    my @m = $en->unit('30m');
    ok(first_of(\@m, unit => 'minute', n => 30, width => 'narrow'), '30m is 30 minutes');
    ok(first_of(\@m, unit => 'month', n => 30), 'and 30 months: CLDR writes both as m in the narrow width, a tie the caller sees');
    ($m) = $X->for('de')->unit('2 Std.');
    is_deeply([ @{$m}{qw(unit n)} ], [ 'hour', 2 ], 'German');
    ($m) = $X->for('ar')->unit('ساعتان');
    is_deeply([ @{$m}{qw(unit n)} ], [ 'hour', 2 ], 'the Arabic dual hour');
    is_deeply($en->digital, { hm => 'h:mm', hms => 'h:mm:ss', ms => 'm:ss' }, 'the digital patterns');
    is($en->lists('unit')->{two}, '{0}, {1}', 'the unit list pattern');
    is($en->lists->{two}, '{0} and {1}', 'the standard one by default');
}

# The cache and the deaths.
{
    is($X->for('en-GB'), $X->for('en_GB'), 'one lexicon a canonical code');
    isnt($X->for('en-GB'), $X->for('en'), 'en-GB is not en');
    dies_like(sub { $X->for('xx-YY') }, qr/^\QTime::Keeper::Natural::Lexicon->for: there is no locale 'xx-YY'\E/, 'a locale that is not there');
    dies_like(sub { $X->for(undef) }, qr/there is no locale ''/, 'none');
}

# English's date and time patterns: datetime first, then date, then time,
# the most letters first within each; MMMM keeps its four letters (the
# unpadded twin takes a pair only when it stands alone).
{
    my %order = (datetime => 0, date => 1, time => 2);
    for my $loc (qw(en fr ja ar-EG)) {
        my @p = $X->for($loc)->patterns;
        my @bad = grep { $order{ $p[$_ - 1]{kind} } > $order{ $p[$_]{kind} }
                      || ($p[$_ - 1]{kind} eq $p[$_]{kind} && $p[$_ - 1]{letters} < $p[$_]{letters}) } 1 .. $#p;
        is(scalar @bad, 0, "$loc: patterns by kind, then most letters first") or diag(join ' / ', map { $p[$_]{pattern} } @bad);
    }
    my @en = map { $_->{pattern} } $X->for('en')->patterns;
    is(scalar @en, 41, 'en has 41 patterns in CLDR 48.2.3');
    is_deeply([ @en[0 .. 3] ], [ "EEEE, MMMM d, y, h:mm:ss\x{202f}a", "MMMM d, y, h:mm:ss\x{202f}a", "MMM d, y, h:mm:ss\x{202f}a", "M/d/yy, h:mm\x{202f}a" ], 'the first four');
    ok(!grep({ /(?<!M)MMM(?!M)/ && !/MMMM/ && /EEEE/ } @en[0 .. 1]), 'no MMMM unpadded to MMM');
}

done_testing;
