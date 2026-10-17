#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use File::Find ();
use File::Spec;

# Installed size: what Time::Keeper and Time::Keeper::Zone put in blib, as
# they would install it, against DateTime, DateTime::TimeZone and
# DateTime::Locale as installed here (their own files, not their
# prerequisites; DateTime::Format::* left out).
sub du {
    my $n = 0;
    File::Find::find({ no_chdir => 1, wanted => sub { $n += -s $_ if -f $_ } }, grep { -e } @_);
    return $n;
}
my $zone = $ENV{TK_ZONE_DIST} // '../Time-Keeper-Zone';
my $mine = du('blib/lib', 'blib/arch') + du("$zone/blib/lib", "$zone/blib/arch");
# DateTime's files are split between perl's arch and lib directories: every
# directory in @INC that has the system's DateTime is counted, once each.
my $theirs = 0;
my (%seen, @dirs);
for my $d (grep { !ref && -d "$_/DateTime" } @INC) {
    next if $ENV{TK_BENCH_LIB} && grep { $d eq $_ } split /:/, $ENV{TK_BENCH_LIB};
    next if $seen{$d}++;
    push @dirs, $d;
    $theirs += -s "$d/DateTime.pm" if -f "$d/DateTime.pm";
    File::Find::find({ no_chdir => 1, wanted => sub {
        if (-d $_ && m{/DateTime/Format\z}) { $File::Find::prune = 1; return }
        $theirs += -s $_ if -f $_;
    } }, grep { -e } "$d/DateTime", "$d/auto/DateTime");
}
my $dir = join ', ', @dirs;
printf "info installed: Time::Keeper and Zone %.1f MB; DateTime, ::TimeZone and ::Locale %.1f MB (in %s)\n",
    $mine / 1e6, $theirs / 1e6, $dir;
mark_less('installed size', sprintf('%.1f', $mine / 1e6), sprintf('%.1f', $theirs / 1e6), 3, 'DateTime', 'MB');
done();
