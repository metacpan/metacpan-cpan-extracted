#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

if (not $ENV{RELEASE_TESTING}) { plan skip_all => 'Release test should only be run on release.'; }

plan tests => 271;

use Encode qw/ decode encode /;
use File::Share qw/ dist_file /;
use Carp::Always;
use JSON::MaybeXS qw/ decode_json /;
use Data::Munge qw/ slurp /;

use Time::C;
use Time::P;
use Time::F;

#binmode STDERR, ":encoding(UTF-8)";

sub in {
    my ($n, @h) = @_;
    foreach my $s (@h) { return 1 if $n eq $s; }
    return 0;
}

my $fn = dist_file 'Time-C', 'locale.db';
open my $fh, '<', $fn or die "Could not open $fn: $!";
my $loc_db = decode_json slurp $fh;

sub loc_db_entries {
    my $l = shift;
    my %entries = map { $_, $loc_db->{$_}{$l} } grep { ref $loc_db->{$_} eq 'HASH' and exists $loc_db->{$_}{$l} } keys %{ $loc_db };
    my @entries;
    foreach my $k (sort keys %entries) {
        my $entry = $entries{$k};
        if (ref $entry eq 'ARRAY') { $entry = join ", ", @{ $entry }; }
        push(@entries, sprintf "%s: %s", $k, $entry);
    }
    return join "\n", @entries;
}

foreach my $l (sort keys %{ $loc_db->{d_t_fmt} }) {
SKIP: {
    skip "$l => Error in d_t spec.", 1 if in($l, qw/ km_KH /);
    skip "$l => Not a proper locale.", 1 if in ($l, qw/ i18n /);
    skip "$l => Error in date spec.", 1 if in ($l, qw/ ms_MY mt_MT id_ID hy_AM /);
    skip "$l => Doesn't actually display a time.", 1 if in ($l, qw/ br_FR /);

    my $t = Time::C->now_utc();

    my $str = eval { strftime($t, "%c", locale => $l); };
    skip "Could not strftime ($l): $@.", 1 if not defined $str;

    note encode 'UTF-8', "$l => $str";
    my $p = eval { Time::C->strptime($str, "%c", locale => $l); };

    if (defined $p) {
        cmp_ok ($p->epoch - $t->epoch, '>=', '-60', "$l => Correct time calculated!") or
          diag sprintf("Error: %s\nStr: %s\n%s\n\n", "$p is not close enough to $t", $str, loc_db_entries($l));
    } else {
        my $err = $@;
        if ($err =~ /^Unsupported format specifier: (%\S+)/) {
            skip "$l => Unsupported format specifier: $1", 1;
        } else {
            fail "$l => Correct time calculated!";
            diag sprintf("Error: %s\nStr: %s\n%s\n\n",
              $err,
              $str,
              loc_db_entries($l));
        }
    }
}
}

#done_testing;
