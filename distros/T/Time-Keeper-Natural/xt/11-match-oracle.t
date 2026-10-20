#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp ();
use FindBin;

# The Match and the errors against the pure-Perl 0.01, in a separate process
# (TKN_ORACLE or ../Time-Keeper-Natural-PP). In thirty locales: relative
# phrases, dates, times, durations, word-table phrases, broken and empty
# texts, padded with spaces, tabs and no-break spaces; each through match,
# match_date and match_duration (every field of the Match), the try_ forms
# (and $@ after them), and parse, parse_date and parse_duration, whose
# deaths are compared whole, "at FILE line N" included, since both sides
# run the same script file. The class forms and options in the wrong place
# are asked too. Offsets are iterated sorted in the oracle, as xt/07 does.
my $oracle = $ENV{TKN_ORACLE} || File::Spec->catdir($FindBin::Bin, '..', '..', 'Time-Keeper-Natural-PP');
plan skip_all => "no oracle at $oracle (set TKN_ORACLE to the pure-Perl 0.01 tree)"
    unless -f File::Spec->catfile($oracle, 'lib', 'Time', 'Keeper', 'Natural.pm');

my $src = do { open my $f, '<:encoding(UTF-8)', File::Spec->catfile($FindBin::Bin, '07-relative-oracle.t') or die; local $/; <$f> };
my ($sorted) = $src =~ /^(if \(\$sorted\) \{\n.*?\n\}\n)/ms or die 'no sorted block in xt/07';

my $script = <<'SCRIPT';
use strict;
use warnings;
use Time::Keeper;
use Time::Keeper::Natural;
my ($out, $sorted, $only) = @ARGV;
open my $fh, '>:encoding(UTF-8)', $out or die "$out: $!";
SORTED
my $L = 'Time::Keeper::Locale';
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, minute => 30, zone => 'Europe/London');
my $N = 'Time::Keeper::Natural';
sub show { my ($v) = @_; return 'undef' unless defined $v; return ref $v eq 'ARRAY' ? '[' . join(',', map { show($_) } @$v) . ']' : "$v" }
sub mshow {
    my ($m) = @_;
    return 'undef' unless $m;
    return join ' | ', ref $m, map { "$_=" . show($_ eq 'assumed' ? [ $m->assumed ] : $m->$_) } qw(value kind precision assumed text start end locale anchor);
}
sub died { my ($code) = @_; my $r = eval { $code->(); 1 }; return $r ? 'lived' : "died: $@" }
my @locales = qw(en en-GB en-US fr de es it pt nl ru ar ar-EG he ja zh ko hi bn th el tr pl sv fi fa ur sw yo zu cy);
for my $loc (@locales) {
    next if defined $only && $loc ne $only;
    my $n = $N->new(locale => $loc, zone => 'Europe/London');
    my $r = $L->relative_names($loc, 'day', 'long');
    my $h = $L->relative_names($loc, 'hour', 'long');
    my $u = $L->unit_patterns($loc, 'hour', 'long');
    my $v = Time::Keeper->new(year => 2026, month => 11, day => 3, hour => 15, minute => 5, zone => 'Europe/London')->in_locale($loc);
    my @texts = grep { defined } $r->{at}{1}, $r->{at}{-1}, ($h->{future}{other} // '') =~ s/\{0\}/3/r, ($u->{count}{other} // '') =~ s/\{0\}/2/r,
        eval { $v->format_date('medium') }, eval { $v->format_time('short') }, eval { $v->format_datetime('short') },
        'end of next month', 'tomorrow at 3 pm', '2026-10-20T15:00:00Z', 'PT90M', '3', 'zzz', '', '   ', '-1 hour', 'in 3 hours 5 pm';
    my @padded = map { ("  $_ ", "\t$_\x{a0}") } grep { length } @texts[0 .. 2];
    for my $t (@texts, @padded, undef) {
        my $shown = defined $t ? $t : '(undef)';
        $shown =~ s/\n/\\n/g;
        my @row = ($loc, $shown);
        push @row, mshow($n->match($t)), mshow($n->match_date($t)), mshow($n->match_duration($t));
        local $@ = 'before';
        push @row, show($n->try_parse($t)) . " $@", show($n->try_parse_date($t)) . " $@", show($n->try_parse_duration($t)) . " $@";
        push @row, died(sub { $n->parse($t) }), died(sub { $n->parse_date($t) }), died(sub { $n->parse_duration($t) });
        my $line = join "\t", @row;
        $line =~ s/\n/\\n/g;
        print $fh "$line\n";
    }
    my @class = (died(sub { $N->parse('zzz', locale => $loc) }), mshow($N->match('tomorrow', locale => $loc, zone => 'Europe/London')),
                 died(sub { $n->match('x', locale => 'fr') }), died(sub { $n->parse('x', zone => 'UTC') }),
                 show($N->try_parse('zzz', locale => $loc)), died(sub { $N->new(locale => $loc, colour => 'red') }));
    my $line = join "\t", $loc, 'class', @class;
    $line =~ s/\n/\\n/g;
    print $fh "$line\n";
}
close $fh;
SCRIPT
$script =~ s/^SORTED\n/$sorted/m;

my $dir = File::Temp->newdir;
my $file = File::Spec->catfile($dir, 'ask.pl');
open my $fh, '>:encoding(UTF-8)', $file or die "$file: $!";
print $fh $script;
close $fh;

sub run {
    my ($name, @inc) = @_;
    my $out = File::Spec->catfile($dir, "$name.txt");
    system($^X, (map { "-I$_" } @inc), $file, $out, $name eq 'oracle' ? 1 : 0, @ARGV) == 0 or die "$name failed: $?";
    open my $in, '<:encoding(UTF-8)', $out or die "$out: $!";
    my @l = <$in>;
    chomp @l;
    return \@l;
}
my $want = run('oracle', File::Spec->catdir($oracle, 'lib'));
my $got = run('ours', @INC);
# 0.02 adds the keep_zone option and 0.03 calendar, which the list of
# options names.
s/bare_hour, prefer, keep_zone and calendar/bare_hour and prefer/g for @$got;
# 0.02 refuses a phrase CLDR writes for two offsets unless prefer picks,
# and assumes the direction when it does; 0.01 read the earlier offset.
my %tie = map { $_ => 1 } grep { defined $got->[$_] && $got->[$_] ne $want->[$_] && $got->[$_] =~ /pass prefer|\bdirection\b/ } 0 .. $#$want;
note(scalar(keys %tie) . " answers differ by 0.02's rule for a phrase with two meanings");
my @bad = grep { !$tie{$_} && (!defined $got->[$_] || $got->[$_] ne $want->[$_]) } 0 .. $#$want;
my $deaths = () = join("\n", @$want) =~ /died: /g;
ok(@$want > 500, scalar(@$want) . " rows, $deaths deaths compared whole");
is(scalar @$got, scalar @$want, 'as many rows');
is(scalar @bad, 0, scalar(@$want) . ' rows agree with the pure-Perl 0.01') or do {
    diag(scalar(@bad) . ' differ');
    for my $i (@bad[0 .. ($#bad < 5 ? $#bad : 5)]) {
        my @w = split /\t/, $want->[$i];
        my @g = split /\t/, $got->[$i] // '';
        for my $c (0 .. $#w) { diag("col $c\n  0.01: $w[$c]\n  C:    " . ($g[$c] // '(none)')) if ($g[$c] // '') ne $w[$c] }
    }
};

done_testing;
