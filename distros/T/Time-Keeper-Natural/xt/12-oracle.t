#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp ();
use FindBin;
use Cwd ();

# The differential oracle: the corpus in xt/oracle-corpus/ (written once by
# tools/oraclecorpus and kept; not shipped) read by the pure-Perl 0.01
# (TKN_ORACLE or ../Time-Keeper-Natural-PP) and by this build, each in one
# process through tools/oracleread, and the two outputs compared byte for
# byte. One line in TKN_ORACLE_EVERY is read (50 by default, about 11,300
# texts in seconds); TKN_ORACLE_EVERY=1 reads all 563,868, about six minutes
# on one core, most of it 0.01's.
my $root = Cwd::abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $oracle = $ENV{TKN_ORACLE} || File::Spec->catdir($root, '..', 'Time-Keeper-Natural-PP');
plan skip_all => "no oracle at $oracle (set TKN_ORACLE to the pure-Perl 0.01 tree)"
    unless -f File::Spec->catfile($oracle, 'lib', 'Time', 'Keeper', 'Natural.pm');
my $dir = File::Spec->catdir($root, 'xt', 'oracle-corpus');
my @files = map { File::Spec->catfile($dir, "$_.txt") } qw(tests relative duration tables formats generated);
plan skip_all => "no corpus in $dir (run tools/oraclecorpus --tests $oracle)" if grep { !-f } @files;
my $every = $ENV{TKN_ORACLE_EVERY} || 50;
my $reader = File::Spec->catfile($root, 'tools', 'oracleread');
my $tmp = File::Temp->newdir;

sub run {
    my ($name, @args) = @_;
    my $out = File::Spec->catfile($tmp, "$name.txt");
    system($^X, @args, $reader, '--every', $every, ($name eq 'oracle' ? '--sorted' : ()), $out, @files) == 0 or die "$name failed: $?";
    open my $in, '<:encoding(UTF-8)', $out or die "$out: $!";
    my @l = <$in>;
    chomp @l;
    return \@l;
}
my $want = run('oracle', '-I' . File::Spec->catdir(Cwd::abs_path($oracle), 'lib'));
my $got = run('ours', map { "-I$_" } @INC);
# 0.02 refuses a phrase CLDR writes for two offsets unless prefer picks,
# and assumes the direction when it does; 0.01 read the earlier offset.
my %tie = map { $_ => 1 } grep { defined $got->[$_] && $got->[$_] ne $want->[$_] && $got->[$_] =~ /pass prefer|\bdirection\b/ } 0 .. $#$want;
note(scalar(keys %tie) . " answers differ by 0.02's rule for a phrase with two meanings");
# 0.02 reads texts 0.01 died on (a zone in the text, a day ordinal): an answer
# may differ only there, the duration's answer the same.
my %gain = map { $_ => 1 } grep {
    my @w = split /\\t/, $want->[$_];
    my @g = split /\\t/, $got->[$_] // '';
    !$tie{$_} && @g >= 4 && $w[2] =~ /^died: / && $w[3] eq $g[3]
        && ($g[2] !~ /^died: /
            # or a table's nth frame (0.04) names why an ordinal weekday does not read
            || ($w[2] =~ /no such word/ && $g[2] =~ /an ordinal weekday is counted in a month|no month has/))
} 0 .. $#$want;
note(scalar(keys %gain) . " texts 0.01 could not read now read");
my @bad = grep { !$tie{$_} && !$gain{$_} && (!defined $got->[$_] || $got->[$_] ne $want->[$_]) } 0 .. $#$want;
my $deaths = grep { /died: / } @$want;
ok(@$want > 1000, scalar(@$want) . " texts (one in $every), $deaths with a death");
is(scalar @$got, scalar @$want, 'as many answers');
is(scalar @bad, 0, scalar(@$want) . ' answers byte-equal to the pure-Perl 0.01') or do {
    my %by;
    push @{ $by{ (split /\\t/, $want->[$_])[0] } }, $_ for @bad;
    diag(scalar(@bad) . ' differ, in ' . join(', ', map { "$_ " . scalar @{ $by{$_} } } sort keys %by));
    for my $i (@bad[0 .. ($#bad < 49 ? $#bad : 49)]) { diag("0.01: $want->[$i]\nport: " . ($got->[$i] // '(none)')) }
};

done_testing;
