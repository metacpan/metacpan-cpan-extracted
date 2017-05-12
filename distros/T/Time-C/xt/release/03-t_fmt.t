#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

if (not $ENV{RELEASE_TESTING}) { plan skip_all => 'Release test should only be run on release.'; }

plan tests => 272;

use Encode qw/ decode encode /;
use File::Share qw/ dist_file /;
use Carp::Always;
use JSON::MaybeXS qw/ decode_json /;
use Data::Munge qw/ slurp /;

use Time::C;
use Time::P;
use Time::F;

binmode STDERR, ":encoding(UTF-8)";

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

foreach my $l (sort keys %{ $loc_db->{t_fmt} }) {
SKIP: {
    skip "$l => Not a proper locale.", 1 if in ($l => qw/ i18n /);
    skip "$l => No AM/PM specifier even though it needs it.", 1 if in ($l =>
qw/ zh_HK /,
qw/ wal_ET /,
qw/ ur_IN /,
qw/ tig_ER ti_ET ti_ER the_NP tcy_IN ta_IN /,
qw/ sq_AL so_SO so_KE so_ET so_DJ sid_ET sd_IN@devanagari sd_IN sat_IN sa_IN /,
qw/ raj_IN /,
qw/ pa_IN /,
qw/ om_KE om_ET /,
qw/ ne_NP /,
qw/ mt_MT ms_MY mr_IN mni_IN ml_IN mag_IN /,
qw/ ks_IN@devanagari ks_IN kok_IN kn_IN /,
qw/ hy_AM hne_IN hi_IN /,
qw/ gu_IN gez_ET gez_ER /,
qw/ en_PH en_IN en_HK /,
qw/ doi_IN /,
qw/ byn_ER brx_IN bn_IN bn_BD bho_IN bhb_IN /,
qw/ ar_YE ar_TN ar_SY ar_SS ar_SD ar_QA ar_OM ar_MA ar_LY ar_LB /,
qw/ ar_KW ar_JO ar_IQ ar_IN ar_EG ar_DZ ar_BH ar_AE anp_IN am_ET /,
qw/ aa_ET aa_ER@saaho aa_ER aa_DJ /,
);
        
        
    my $t = Time::C->now_utc();

		my $str = eval { strftime($t, '%X', locale => $l); };
		skip "Could not strftime ($l): $@.", 1 if not defined $str;

    note encode 'UTF-8', "$l => $str";
    my $p = eval { Time::C->strptime($str, "%X", locale => $l); };

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
              encode('UTF-8', $err),
              $str,
              loc_db_entries($l));
        }
    }
}
}

#done_testing;
