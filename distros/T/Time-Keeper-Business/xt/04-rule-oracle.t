#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin ();

# Author test: the rules against the pure-Perl implementation they were
# ported from (xt/RuleOracle.pl, Rule.pm as it stood in October 2026),
# built the same way from the same random recipes, compared year by year.

use Time::Keeper;
use Time::Keeper::Business;
require "$FindBin::Bin/RuleOracle.pl";

my ($X, $P) = ('Time::Keeper::Business::Rule', 'Time::Keeper::Business::RuleOracle');
srand($ENV{TKB_SEED} // 20261018);

my @forms = ('none', 'next_business_day', 'nearest_business_day', 'next_monday');
sub recipe {
    my $depth = shift;
    my $k = int(rand(5));
    my %r;
    if ($k == 0) { my $m = 1 + int(rand(12)); %r = (kind => 'fixed', args => [ month => $m, day => 1 + int(rand($m == 2 ? 29 : 30)) ]) }
    elsif ($k == 1) { %r = (kind => 'nth', args => [ month => 1 + int(rand(12)), day_of_week => 1 + int(rand(7)), n => (-1, 1 .. 5)[int(rand(6))] ]) }
    elsif ($k == 2) { %r = (kind => 'easter', args => [ offset => int(rand(121)) - 60, orthodox => int(rand(2)) ]) }
    elsif ($k == 3) { %r = (kind => 'relative', base => recipe(99), args => [ days => int(rand(21)) - 10 ]) }
    else {
        return recipe($depth) if $depth >= 2;
        %r = (kind => 'set', members => [ map { recipe($depth + 1) } 0 .. int(rand(5)) ], args => [ (rand() < 0.3 ? (weekend => [ grep { rand() < 0.4 } 1 .. 6 ]) : ()) ]);
    }
    push @{ $r{args} }, name => "h$k" . int(rand(1000)) if rand() < 0.8;
    $r{observed} = $forms[ int(rand(@forms)) ] if $r{kind} ne 'set' && rand() < 0.5;
    $r{obs_weekend} = [ grep { rand() < 0.4 } 1 .. 6 ] if $r{observed} && rand() < 0.2;
    $r{between} = [ (rand() < 0.5 ? (from => 1990 + int(rand(60))) : ()), (rand() < 0.5 ? (to => 2000 + int(rand(60))) : ()) ] if rand() < 0.2;
    $r{only_if} = int(rand(3)) + 2 if rand() < 0.15;
    return \%r;
}
sub build {
    my ($class, $r) = @_;
    my $rule;
    if ($r->{kind} eq 'set') { $rule = $class->set((map { build($class, $_) } @{ $r->{members} }), @{ $r->{args} }) }
    elsif ($r->{kind} eq 'relative') {
        my $base = build($class, $r->{base});
        $base = build($class, { kind => 'fixed', args => [ month => 3, day => 1 ] }) if $r->{base}{kind} eq 'set';
        $rule = $class->relative(rule => $base, @{ $r->{args} });
    }
    else { my $k = $r->{kind}; $rule = $class->$k(@{ $r->{args} }) }
    $rule = $rule->observed($r->{observed}, ($r->{obs_weekend} ? (weekend => $r->{obs_weekend}) : ())) if $r->{observed};
    $rule = $rule->between(@{ $r->{between} }) if $r->{between};
    if (my $mod = $r->{only_if}) { $rule = $rule->only_if(sub { $_[0] % $mod }) }
    return $rule;
}
sub flat { join ' ', map { "$_->[0]=" . ($_->[1] // '~') } @_ }

my ($rules, $years, $bad) = (0, 0, 0);
for (1 .. 3000) {
    my $r = recipe(0);
    my ($x, $p) = (build($X, $r), build($P, $r));
    $rules++;
    for (1 .. 8) {
        my $year = 1900 + int(rand(300));
        my $got = eval { flat($x->holidays(year => $year)) } // "died: $@";
        my $want = eval { flat($p->holidays(year => $year)) } // "died: $@";
        s/ at \S+ line \d+\.?\n?//g for $got, $want;
        $years++;
        next if $got eq $want;
        next if $got =~ /^died: .*every day/ && $want =~ /^died/;
        $bad++;
        diag("year $year\n  xs:   $got\n  perl: $want") if $bad <= 5;
    }
}
is($bad, 0, "$rules random rules over $years years agree with the Perl implementation");

for my $set (qw(uk us_federal target2)) {
    my ($x, $p) = ($X->$set, $P->$set);
    my $diff = grep { flat($x->holidays(year => $_)) ne flat($p->holidays(year => $_)) } 1900 .. 2199;
    is($diff, 0, "$set agrees for 1900 to 2199");
    is($x->name, $p->name, "  and its name");
}

done_testing;
