#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;

# Author test: every locale's names and formats against CLDR's own JSON,
# read here afresh, and against DateTime::Locale, whose differences must
# each be a change between the CLDR it was built from and the one here.
#
#   TK_CLDR_JSON=dir     cldr-json 48.2.3 unpacked (cldr-core, cldr-dates-full)
#   TK_CLDR47_JSON=dir   cldr-json 47.0.0 unpacked, the release DateTime::Locale 1.45 is from

plan skip_all => 'set TK_CLDR_JSON to an unpacked cldr-json 48.2.3' unless $ENV{TK_CLDR_JSON};

use JSON::PP ();
use Time::Keeper;
use Time::Keeper::Locale;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $L = 'Time::Keeper::Locale';
my $json = JSON::PP->new->utf8;
sub jfile { my ($f) = @_; open my $fh, '<:raw', $f or return undef; local $/; $json->decode(<$fh>) }

# The data a code is read from: a default-content code is its parent's.
sub source {
    my ($dir, $code) = @_;
    my $c = $code;
    $c =~ s/-[^-]+\z// while $c =~ /-/ && !-d "$dir/cldr-dates-full/main/$c";
    return -d "$dir/cldr-dates-full/main/$c" ? $c : undef;
}

my %ctx = ('format' => 'format', 'stand-alone' => 'stand-alone');
my @days = qw(mon tue wed thu fri sat sun);
my %era_key = (wide => 'eraNames', abbreviated => 'eraAbbr', narrow => 'eraNarrow');

# Every name and format of a locale, as CLDR's JSON has them, keyed alike.
sub cldr_data {
    my ($dir, $code) = @_;
    my $src = source($dir, $code) // return undef;
    my $g = jfile("$dir/cldr-dates-full/main/$src/ca-gregorian.json")->{main}{$src}{dates}{calendars}{gregorian};
    my %d;
    for my $c (keys %ctx) {
        for my $w (qw(wide abbreviated narrow)) {
            $d{"months $w $c"} = join '|', map { $g->{months}{$c}{$w}{$_} } 1 .. 12;
            $d{"quarters $w $c"} = join '|', map { $g->{quarters}{$c}{$w}{$_} } 1 .. 4;
        }
        for my $w (qw(wide abbreviated narrow short)) {
            $d{"days $w $c"} = join '|', map { $g->{days}{$c}{$w}{$_} } @days;
        }
    }
    for my $w (qw(wide abbreviated narrow)) {
        $d{"eras $w"} = join '|', map { $g->{eras}{ $era_key{$w} }{$_} } 0, 1;
        $d{"am_pm $w"} = join '|', map { $g->{dayPeriods}{format}{$w}{$_} } qw(am pm);
    }
    for my $k (qw(date time datetime)) {
        my $key = { date => 'dateFormats', time => 'timeFormats', datetime => 'dateTimeFormats' }->{$k};
        $d{"formats $k"} = join '|', map {
            my $v = $g->{$key}{$_};
            ref $v ? $v->{_value} // $v->{standard} : $v;
        } qw(full long medium short);
    }
    my $a = $g->{dateTimeFormats}{availableFormats};
    $d{"available"} = join '|', map { "$_=$a->{$_}" } sort grep { !ref $a->{$_} } keys %$a;
    return \%d;
}

sub from_keeper {
    my ($code) = @_;
    my %d;
    for my $c (keys %ctx) {
        for my $w (qw(wide abbreviated narrow)) {
            $d{"months $w $c"} = join '|', $L->names($code, 'months', $w, $c);
            $d{"quarters $w $c"} = join '|', $L->names($code, 'quarters', $w, $c);
        }
        $d{"days $_ $c"} = join '|', $L->names($code, 'days', $_, $c) for qw(wide abbreviated narrow short);
    }
    for my $w (qw(wide abbreviated narrow)) {
        $d{"eras $w"} = join '|', $L->names($code, 'eras', $w);
        $d{"am_pm $w"} = join '|', $L->names($code, 'am_pm', $w);
    }
    $d{"formats $_"} = join '|', $L->formats($code, $_) for qw(date time datetime);
    my $a = $L->available_formats($code);
    $d{"available"} = join '|', map { "$_=$a->{$_}" } sort keys %$a;
    return \%d;
}

# 1. Against CLDR 48's JSON.
my $dir = $ENV{TK_CLDR_JSON};
my ($fields, @wrong) = (0);
for my $code ($L->codes) {
    my $j = cldr_data($dir, $code) or do { push @wrong, "$code: not in the JSON"; next };
    my $k = from_keeper($code);
    for my $f (sort keys %$j) {
        $fields++;
        push @wrong, "$code $f: '$k->{$f}' not '$j->{$f}'" if $k->{$f} ne $j->{$f};
    }
}
is(scalar @wrong, 0, "every locale's names and formats are CLDR 48's ($fields fields)")
    or diag(join "\n", @wrong[0 .. 19]);

# 2. Zone names against CLDR 48's JSON: each metazone's long names, written
# for its golden zone in January and July.
{
    my $mz = jfile("$dir/cldr-core/supplemental/metaZones.json")->{supplemental}{metaZones};
    my %golden = map { $_->{mapZone}{_other} => $_->{mapZone}{_type} }
                 grep { ($_->{mapZone}{_territory} // '') eq '001' } @{ $mz->{metazones} };
    my ($checked, @bad) = (0);
    for my $code (qw(en fr de ja ar ru zh es pt hi ko it)) {
        my $tzn = jfile("$dir/cldr-dates-full/main/$code/timeZoneNames.json")->{main}{$code}{dates}{timeZoneNames};
        for my $m (sort keys %{ $tzn->{metazone} }) {
            my $zone = $golden{$m} or next;
            my ($own, $uses) = ($tzn->{zone}, $mz->{metazoneInfo}{timezone});
            for my $part (split m{/}, $zone) {
                $own = ref $own eq 'HASH' ? $own->{$part} : undef;
                $uses = ref $uses eq 'HASH' ? $uses->{$part} : undef;
            }
            next if ref $own eq 'HASH' && ($own->{long} || $own->{short});
            next unless ref $uses eq 'ARRAY' && grep {
                my $u = $_->{usesMetazone};
                $u->{_mzone} eq $m && ($u->{_from} // '0') le '2026-01-01' && ($u->{_to} // '9') gt '2026-08-01'
            } @$uses;
            for my $month (1, 7) {
                my $v = eval { Time::Keeper->new(year => 2026, month => $month, day => 15, hour => 12,
                                                 zone => $zone, locale => $code) } or next;
                my $want = $tzn->{metazone}{$m}{long}{ $v->is_dst ? 'daylight' : 'standard' } // next;
                my $got = $v->format('zzzz');
                $checked++;
                push @bad, "$code $zone ($m) $month: '$got' not '$want'" if $got ne $want;
            }
        }
    }
    is(scalar @bad, 0, "metazone names are CLDR 48's ($checked checked)") or diag(join "\n", @bad[0 .. 19]);
}

# 3. Against DateTime::Locale: each difference must be one between CLDR 47
# and 48.
SKIP: {
    skip 'DateTime::Locale and TK_CLDR47_JSON are needed', 2
        unless $ENV{TK_CLDR47_JSON} && eval { require DateTime::Locale; DateTime::Locale->VERSION(1.45); 1 };
    my $d47 = $ENV{TK_CLDR47_JSON};
    my %map = (
        'months wide format'            => 'month_format_wide',
        'months abbreviated format'     => 'month_format_abbreviated',
        'months narrow format'          => 'month_format_narrow',
        'months wide stand-alone'       => 'month_stand_alone_wide',
        'months abbreviated stand-alone'=> 'month_stand_alone_abbreviated',
        'months narrow stand-alone'     => 'month_stand_alone_narrow',
        'days wide format'              => 'day_format_wide',
        'days abbreviated format'       => 'day_format_abbreviated',
        'days narrow format'            => 'day_format_narrow',
        'days wide stand-alone'         => 'day_stand_alone_wide',
        'days abbreviated stand-alone'  => 'day_stand_alone_abbreviated',
        'days narrow stand-alone'       => 'day_stand_alone_narrow',
        'eras wide'                     => 'era_wide',
        'eras abbreviated'              => 'era_abbreviated',
        'eras narrow'                   => 'era_narrow',
        'am_pm abbreviated'             => 'am_pm_abbreviated',
    );
    my ($same, $explained, @unexplained) = (0, 0);
    my %by_field;
    for my $code (DateTime::Locale->codes) {
        my $dl = DateTime::Locale->load($code);
        my $k = from_keeper($code);
        my $j47 = cldr_data($d47, $code) or do { push @unexplained, "$code: not in CLDR 47"; next };
        my $j48 = cldr_data($dir, $code);
        my %dt = map { $_ => join('|', @{ $dl->${ \$map{$_} } }) } keys %map;
        $dt{'formats date'} = join '|', map { $dl->${ \"date_format_$_" } } qw(full long medium short);
        $dt{'formats time'} = join '|', map { $dl->${ \"time_format_$_" } } qw(full long medium short);
        for my $f (sort keys %dt) {
            if ($dt{$f} eq $k->{$f}) { $same++; next }
            if ($dt{$f} eq $j47->{$f} && $j47->{$f} ne $j48->{$f}) { $explained++; $by_field{$f}++; next }
            push @unexplained, "$code $f: DateTime::Locale '$dt{$f}', Time::Keeper '$k->{$f}', CLDR 47 '$j47->{$f}'";
        }
    }
    diag("the same: $same; changed between CLDR 47 and 48: $explained");
    diag("  $by_field{$_} $_") for sort { $by_field{$b} <=> $by_field{$a} } keys %by_field;
    is(scalar @unexplained, 0, 'every difference from DateTime::Locale is a change in CLDR')
        or diag(join "\n", @unexplained[0 .. 19]);
    is(scalar(grep { !defined $L->code($_) } DateTime::Locale->codes), 0, 'every code DateTime::Locale has is one here');
}

# ---- archive version 3: the words ----------------------------------------------
# Every locale's relative-time words, duration units, list patterns, interval
# formats and weekend days against the JSON they were compiled from
# (cldr-units-full and cldr-misc-full must be in TK_CLDR_JSON too), and every
# plural rule against CLDR's own @integer samples.
{
    my @rel_fields = qw(year quarter month week day hour minute second);
    my @cats = qw(zero one two few many other);
    my @dur_units = qw(year month week day hour minute second millisecond microsecond nanosecond);
    my $bad = 0;
    my $checked = 0;
    my $note = sub { $bad++; diag(shift) if $bad <= 30 };
    my $week = jfile("$dir/cldr-core/supplemental/weekData.json")->{supplemental}{weekData};
    my $likely = jfile("$dir/cldr-core/supplemental/likelySubtags.json")->{supplemental}{likelySubtags};
    my %dayno = (mon => 1, tue => 2, wed => 3, thu => 4, fri => 5, sat => 6, sun => 7);
    for my $code ($L->codes) {
        my $src = source($dir, $code) // next;
        my $df = jfile("$dir/cldr-dates-full/main/$src/dateFields.json")->{main}{$src}{dates}{fields};
        my $un = jfile("$dir/cldr-units-full/main/$src/units.json")->{main}{$src}{units};
        my $lp = jfile("$dir/cldr-misc-full/main/$src/listPatterns.json")->{main}{$src}{listPatterns};
        my $iv = jfile("$dir/cldr-dates-full/main/$src/ca-gregorian.json")->{main}{$src}{dates}{calendars}{gregorian}{dateTimeFormats}{intervalFormats};
        for my $fld (@rel_fields) {
            for my $w (['long', ''], ['short', '-short'], ['narrow', '-narrow']) {
                my $e = $df->{"$fld$w->[1]"} // {};
                my $r = $L->relative_names($code, $fld, $w->[0]);
                my %want_at = map { my $v = $e->{"relative-type-$_"}; defined $v ? ($_ => $v) : () } -2 .. 2;
                $note->("$code $fld $w->[0] display") unless (($r->{display} // '') eq ($e->{displayName} // ''));
                $note->("$code $fld $w->[0] at") unless join('|', map { "$_=$want_at{$_}" } sort keys %want_at) eq join('|', map { "$_=$r->{at}{$_}" } sort keys %{ $r->{at} });
                for my $dir2 (qw(future past)) {
                    my %want = map { my $v = $e->{"relativeTime-type-$dir2"}{"relativeTimePattern-count-$_"}; defined $v ? ($_ => $v) : () } @cats;
                    $note->("$code $fld $w->[0] $dir2") unless join('|', map { "$_=$want{$_}" } sort keys %want) eq join('|', map { "$_=$r->{$dir2}{$_}" } sort keys %{ $r->{$dir2} });
                }
                $checked += 4;
            }
        }
        for my $u (@dur_units) {
            for my $w (qw(long short narrow)) {
                my $e = $un->{$w}{"duration-$u"} // {};
                my $r = $L->unit_patterns($code, $u, $w);
                my %want = map { my $v = $e->{"unitPattern-count-$_"}; defined $v ? ($_ => $v) : () } @cats;
                $note->("$code $u $w display") unless (($r->{display} // '') eq ($e->{displayName} // ''));
                $note->("$code $u $w count") unless join('|', map { "$_=$want{$_}" } sort keys %want) eq join('|', map { "$_=$r->{count}{$_}" } sort keys %{ $r->{count} });
                $checked += 2;
            }
        }
        my $dp = $L->duration_patterns($code);
        for my $k (qw(hm hms ms)) {
            $note->("$code durationUnit $k") unless (($dp->{$k} // '') eq ($un->{"durationUnit-type-$k"}{durationUnitPattern} // ''));
            $checked++;
        }
        for my $t (qw(standard unit unit-short unit-narrow)) {
            my $e = $lp->{"listPattern-type-$t"} // {};
            my $r = $L->list_patterns($code, $t);
            $note->("$code list $t") unless join('|', map { $e->{$_} // '' } qw(start middle end 2)) eq join('|', map { $r->{$_} // '' } qw(start middle end two));
            $checked++;
        }
        my $all = $L->interval_formats($code);
        my %want_iv;
        for my $k (keys %$iv) {
            next if $k eq 'intervalFormatFallback' || !ref $iv->{$k};
            for my $l (keys %{ $iv->{$k} }) { $want_iv{"$k/$l"} = $iv->{$k}{$l} if length($l) == 1 && !ref $iv->{$k}{$l} }
        }
        my %got_iv = map { my $k = $_; map { ("$k/$_" => $all->{$k}{$_}) } keys %{ $all->{$k} } } keys %$all;
        $note->("$code interval formats") unless join('|', map { "$_=$want_iv{$_}" } sort keys %want_iv) eq join('|', map { "$_=$got_iv{$_}" } sort keys %got_iv);
        $note->("$code interval fallback") unless (($L->interval_fallback($code) // '') eq ($iv->{intervalFormatFallback} // ''));
        # the territory of the SOURCE: a default-content code shares its parent's section, weekend included
        my ($terr) = grep { defined && /^(?:[A-Z]{2}|\d{3})\z/ } (split /-/, $src)[1 .. 3];
        unless ($terr) {
            my $l = $likely->{$src} // $likely->{ (split /-/, $src)[0] } // $likely->{und};
            ($terr) = grep { /^(?:[A-Z]{2}|\d{3})\z/ } split /-/, $l;
        }
        $terr //= '001';
        my $ws = $dayno{ $week->{weekendStart}{$terr} // $week->{weekendStart}{'001'} };
        my $we = $dayno{ $week->{weekendEnd}{$terr} // $week->{weekendEnd}{'001'} };
        $note->("$code weekend") unless $L->weekend_start($code) == $ws && $L->weekend_end($code) == $we;
        $checked += 3;
    }
    is($bad, 0, "the words of every locale agree with the JSON ($checked checks)");

    my $plurals = jfile("$dir/cldr-core/supplemental/plurals.json")->{supplemental}{'plurals-type-cardinal'};
    my ($pbad, $pchecked) = (0, 0);
    for my $key (sort keys %$plurals) {
        my $loc = $L->code($key) // next;
        for my $cat (@cats) {
            my $rule = $plurals->{$key}{"pluralRule-count-$cat"} // next;
            my ($samples) = $rule =~ /\@integer\s+([^@]*)/ or next;
            for my $tok (split /\s*,\s*/, $samples) {
                next unless defined $tok;
                $tok =~ s/\s+//g;
                next if $tok eq '' || $tok =~ /…|c|\.{3}/;
                my @ns = $tok =~ /^(\d+)~(\d+)$/ ? ($1 .. $2) : $tok =~ /^\d+$/ ? ($tok) : ();
                for my $n (@ns) {
                    my $got = $L->plural_category($loc, $n);
                    unless ($got eq $cat) { $pbad++; diag("$key ($loc): $n is $got, CLDR says $cat") if $pbad <= 30 }
                    $pchecked++;
                }
            }
        }
    }
    is($pbad, 0, "every plural rule agrees with CLDR's integer samples ($pchecked numbers)");
}

done_testing;
