# Parity: Time::Piece, DateTime and Time::Keeper

Every public method of Time::Piece 1.36, Time::Seconds 1.36, DateTime 1.66,
DateTime::Duration 1.66, DateTime::TimeZone 2.66, DateTime::Locale 1.45 (with
DateTime::Locale::FromData) and DateTime::Infinite 1.66, and what does its job in
Time::Keeper. The method lists are those the modules' symbol tables held on perl 5.42 on
15 October 2026 (`plan_time_keeper/sources/`).

`xt/11-parity.t` reads this file. It checks that every method of the lists has one row,
that every method a row's Time::Keeper column calls exists, that every test file named
exists, and that every row marked `oracle` gives the same answer as the module it
replaces on random values. A row marked "not provided" must name a reason the owner has
accepted.

## How a row is read

The **theirs** and **Time::Keeper** columns are Perl. In them:

| name | is |
|---|---|
| `$dt`, `$dt2`, `$dt3` | DateTime values: random instants from 1938 to 2096, each in a random zone, English |
| `$t`, `$t2`, `$t3` | the same instants as Time::Keeper values, in the same zones |
| `$tp`, `$tp2` | Time::Piece values from `gmtime`; then `$t`, `$t2` are the same instants in UTC |
| `$ts` | a Time::Seconds of a random number of seconds; `$s` is `$D->from_seconds` of it |
| `$dd`, `$dd2` | DateTime::Duration values of random months, days, minutes, seconds, nanoseconds, all of one sign; `$d`, `$d2` the same as Time::Keeper::Duration |
| `P($x)` | a duration's months, days, minutes, seconds and nanoseconds, joined with commas |
| `$tz`, `$zone` | `$dt`'s zone as a DateTime::TimeZone, and its name |
| `$loc`, `$code` | a DateTime::Locale and its code: en, fr, de, ja, es, it |
| `$K`, `$D`, `$L`, `$Z` | `Time::Keeper`, `Time::Keeper::Duration`, `Time::Keeper::Locale`, `Time::Keeper::Zone` |

The **check** column:

- `oracle`: both columns are run on 2,000 random values and must agree; `oracle utc`
  runs them in UTC only (arithmetic, where DateTime's choice in a DST overlap is not
  Time::Keeper's, K3), and `oracle local` with Time::Piece's `localtime` in
  America/New_York.
- a test file: the behaviour is tested there.
- `ruled`: the owner's ruling, by its number in `plan_time_keeper/00-overview.md`.
- `struck`: not a public method (an imported helper, an overload's internals, or
  undocumented), with the reason.
- `not provided (N#)`: no equivalent, for the reason under [Not provided](#not-provided).

## DateTime 1.66

| method | theirs | Time::Keeper | check | note |
|---|---|---|---|---|
| `(""` | `"$dt"` | `"$t"` | t/12-overload.t | RFC 3339 with the offset and any fraction; DateTime writes the wall clock alone. `$t->strftime('%FT%T')` is DateTime's form |
| `(+` | `($dt + DateTime::Duration->new(days => 3))->iso8601` | `($t + $D->new(days => 3))->strftime('%FT%T')` | oracle utc | |
| `(-` | `$dt - $dt2` | `$t - $t2` | ruled K12 | months before days, so `$t2 + ($t - $t2) == $t` always; DateTime's does not round-trip in 1.5% of pairs. t/15-arith.t |
| `(<=>` | `$dt <=> $dt2` | `$t <=> $t2` | oracle | |
| `(cmp` | `$dt cmp $dt2` | `$t cmp $t2` | oracle | |
| `(bool` | `$dt ? 1 : 0` | `$t ? 1 : 0` | oracle | |
| `(eq` | `$dt eq $dt2` | `$t eq $t2` | oracle | |
| `(ne` | `$dt ne $dt2` | `$t ne $t2` | oracle | |
| `((` | | | struck: overload's bookkeeping | |
| `()` | | | struck: overload's bookkeeping | |
| `DefaultLocale` | `DateTime->DefaultLocale('fr')` | `$K->now(locale => 'fr')` | not provided (N1) | |
| `STORABLE_freeze` | `Storable::freeze($dt)` | `Storable::freeze($t)` | t/13-handles.t | |
| `STORABLE_thaw` | `Storable::thaw(Storable::freeze($dt))` | `Storable::thaw(Storable::freeze($t))` | t/13-handles.t | |
| `add` | `$dt->clone->add(months => 1)->iso8601` | `$t->plus(months => 1)->strftime('%FT%T')` | oracle utc | |
| `add_duration` | `$dt->clone->add_duration(DateTime::Duration->new(days => 3))->iso8601` | `$t->plus($D->new(days => 3))->strftime('%FT%T')` | oracle utc | |
| `am_or_pm` | `$dt->am_or_pm` | `$t->am_pm` | oracle | |
| `assert_ArrayRef` | | | struck: imported from Specio | |
| `assert_Bool` | | | struck: imported from Specio | |
| `assert_ClassName` | | | struck: imported from Specio | |
| `assert_CodeRef` | | | struck: imported from Specio | |
| `assert_Defined` | | | struck: imported from Specio | |
| `assert_FileHandle` | | | struck: imported from Specio | |
| `assert_GlobRef` | | | struck: imported from Specio | |
| `assert_HashRef` | | | struck: imported from Specio | |
| `assert_Int` | | | struck: imported from Specio | |
| `assert_Item` | | | struck: imported from Specio | |
| `assert_Maybe` | | | struck: imported from Specio | |
| `assert_Num` | | | struck: imported from Specio | |
| `assert_Object` | | | struck: imported from Specio | |
| `assert_Ref` | | | struck: imported from Specio | |
| `assert_RegexpRef` | | | struck: imported from Specio | |
| `assert_ScalarRef` | | | struck: imported from Specio | |
| `assert_Str` | | | struck: imported from Specio | |
| `assert_Undef` | | | struck: imported from Specio | |
| `assert_Value` | | | struck: imported from Specio | |
| `bootstrap` | | | struck: XSLoader's | |
| `ce_year` | `$dt->ce_year` | `$t->year > 0 ? $t->year : $t->year - 1` | oracle | |
| `christian_era` | `$dt->christian_era` | `$t->era_abbr` | oracle | |
| `clone` | `$dt->clone` | `$t` | ruled K1 | values never change, so a value is its own copy |
| `compare` | `DateTime->compare($dt, $dt2)` | `$K->compare($t, $t2)` | oracle | |
| `compare_ignore_floating` | `DateTime->compare_ignore_floating($dt, $dt2)` | `$K->compare($t->is_floating ? $t->as_utc : $t, $t2->is_floating ? $t2->as_utc : $t2)` | oracle | |
| `date` | `$dt->date` | `$t->date` | oracle | |
| `datetime` | `$dt->datetime` | `$t->strftime('%FT%T')` | oracle | |
| `day` | `$dt->day` | `$t->day` | oracle | |
| `day_0` | `$dt->day_0` | `$t->day - 1` | oracle | |
| `day_abbr` | `$dt->day_abbr` | `$t->day_abbr` | oracle | |
| `day_name` | `$dt->day_name` | `$t->day_name` | oracle | |
| `day_of_month` | `$dt->day_of_month` | `$t->day` | oracle | |
| `day_of_month_0` | `$dt->day_of_month_0` | `$t->day - 1` | oracle | |
| `day_of_quarter` | `$dt->day_of_quarter` | `$t->day_of_quarter` | oracle | |
| `day_of_quarter_0` | `$dt->day_of_quarter_0` | `$t->day_of_quarter - 1` | oracle | |
| `day_of_week` | `$dt->day_of_week` | `$t->day_of_week` | oracle | |
| `day_of_week_0` | `$dt->day_of_week_0` | `$t->day_of_week - 1` | oracle | |
| `day_of_year` | `$dt->day_of_year` | `$t->day_of_year` | oracle | |
| `day_of_year_0` | `$dt->day_of_year_0` | `$t->day_of_year - 1` | oracle | |
| `delta_days` | `$dt->delta_days($dt2)->in_units('days')` | `$t->delta_days($t2)->in_units('days')` | oracle utc | |
| `delta_md` | `join ',', $dt->delta_md($dt2)->in_units('months', 'days')` | `join ',', $t->delta_md($t2)->in_units('months', 'days')` | ruled K12 | DateTime counts the days left over with the earlier month's length, so the earlier date plus its answer is not the later (1972-11-24 and 2004-11-02: 383 months and 8 days, which add to 2004-11-01); here they add back. 26% of random pairs differ. t/15-arith.t |
| `delta_ms` | `join ',', $dt->delta_ms($dt2)->in_units('minutes', 'seconds')` | `join ',', $t->delta_ms($t2)->in_units('minutes', 'seconds')` | oracle utc | |
| `dmy` | `$dt->dmy('/')` | `$t->dmy('/')` | oracle | |
| `doq` | `$dt->doq` | `$t->day_of_quarter` | oracle | |
| `doq_0` | `$dt->doq_0` | `$t->day_of_quarter - 1` | oracle | |
| `dow` | `$dt->dow` | `$t->day_of_week` | oracle | |
| `dow_0` | `$dt->dow_0` | `$t->day_of_week - 1` | oracle | |
| `doy` | `$dt->doy` | `$t->day_of_year` | oracle | |
| `doy_0` | `$dt->doy_0` | `$t->day_of_year - 1` | oracle | |
| `duration_class` | `$dt->duration_class` | `$D` | not provided (N4) | |
| `epoch` | `$dt->epoch` | `$t->epoch` | oracle | |
| `era` | `$dt->era` | `$t->era_abbr` | oracle | |
| `era_abbr` | `$dt->era_abbr` | `$t->era_abbr` | oracle | |
| `era_name` | `$dt->era_name` | `$t->era_name` | oracle | |
| `format_cldr` | `$dt->format_cldr('EEEE d MMMM y HH:mm:ss.SSS a')` | `$t->format('EEEE d MMMM y HH:mm:ss.SSS a')` | oracle | where the standard and DateTime differ the standard is followed: see FORMATTING in the POD and xt/08-format-oracle.t |
| `formatter` | `$dt->formatter` | `$t->format('...')` | not provided (N2) | |
| `fractional_second` | `$dt->fractional_second` | `$t->second + $t->nanosecond / 1e9` | oracle | |
| `from_day_of_year` | `DateTime->from_day_of_year(year => 2028, day_of_year => 366)->ymd` | `$K->from_day_of_year(year => 2028, day_of_year => 366)->ymd` | oracle | |
| `from_epoch` | `DateTime->from_epoch(epoch => $dt->epoch)->iso8601` | `$K->from_epoch($t->epoch)->strftime('%FT%T')` | oracle | |
| `from_object` | `DateTime->from_object(object => $dt)->epoch` | `$K->from_object(object => $dt)->epoch` | oracle | and `DateTime->from_object(object => $t)` works too: t/24-interop.t |
| `hires_epoch` | `$dt->hires_epoch` | `$t->hires_epoch` | oracle | |
| `hms` | `$dt->hms('.')` | `$t->hms('.')` | oracle | |
| `hour` | `$dt->hour` | `$t->hour` | oracle | |
| `hour_1` | `$dt->hour_1` | `$t->format('k')` | oracle | |
| `hour_12` | `$dt->hour_12` | `$t->format('h')` | oracle | |
| `hour_12_0` | `$dt->hour_12_0` | `$t->format('K')` | oracle | |
| `is_ArrayRef` | | | struck: imported from Specio | |
| `is_Bool` | | | struck: imported from Specio | |
| `is_ClassName` | | | struck: imported from Specio | |
| `is_CodeRef` | | | struck: imported from Specio | |
| `is_Defined` | | | struck: imported from Specio | |
| `is_FileHandle` | | | struck: imported from Specio | |
| `is_GlobRef` | | | struck: imported from Specio | |
| `is_HashRef` | | | struck: imported from Specio | |
| `is_Int` | | | struck: imported from Specio | |
| `is_Item` | | | struck: imported from Specio | |
| `is_Maybe` | | | struck: imported from Specio | |
| `is_Num` | | | struck: imported from Specio | |
| `is_Object` | | | struck: imported from Specio | |
| `is_Ref` | | | struck: imported from Specio | |
| `is_RegexpRef` | | | struck: imported from Specio | |
| `is_ScalarRef` | | | struck: imported from Specio | |
| `is_Str` | | | struck: imported from Specio | |
| `is_Undef` | | | struck: imported from Specio | |
| `is_Value` | | | struck: imported from Specio | |
| `is_between` | `$dt->is_between($dt2, $dt3)` | `$t2 < $t && $t < $t3` | oracle | |
| `is_dst` | `$dt->is_dst` | `$t->is_dst` | oracle | |
| `is_finite` | `$dt->is_finite` | `1` | not provided (N3) | every value is finite |
| `is_infinite` | `$dt->is_infinite` | `0` | not provided (N3) | |
| `is_last_day_of_month` | `$dt->is_last_day_of_month` | `$t->day == $t->days_in_month` | oracle | |
| `is_last_day_of_quarter` | `$dt->is_last_day_of_quarter` | `$t->day_of_quarter == $t->days_in_quarter` | oracle | |
| `is_last_day_of_year` | `$dt->is_last_day_of_year` | `$t->day_of_year == $t->days_in_year` | oracle | |
| `is_leap_year` | `$dt->is_leap_year` | `$t->is_leap_year` | oracle | |
| `iso8601` | `$dt->iso8601` | `$t->strftime('%FT%T')` | oracle | `$t->iso8601` adds the offset and any fraction, as ISO 8601 allows |
| `jd` | `$dt->jd` | `$t->julian_day` | oracle | |
| `last_day_of_month` | `DateTime->last_day_of_month(year => 2028, month => 2)->ymd` | `$K->last_day_of_month(year => 2028, month => 2)->ymd` | oracle | |
| `leap_seconds` | `$dt->leap_seconds` | `($t->tai_offset // 10) - 10` | oracle | |
| `local_day_of_week` | `$dt->local_day_of_week` | `$t->format('e')` | t/22-locale.t | DateTime::Locale starts English's week on Monday; CLDR's likely region for `en` is the United States, whose week starts on Sunday |
| `local_rd_as_seconds` | `$dt->local_rd_as_seconds` | `($t->local_rd_values)[0] * 86400 + ($t->local_rd_values)[1]` | oracle | |
| `local_rd_values` | `join ',', $dt->local_rd_values` | `join ',', $t->local_rd_values` | oracle | |
| `locale` | `$dt->locale->code` | `$t->locale` | oracle | a code; `Time::Keeper::Locale` answers for it |
| `mday` | `$dt->mday` | `$t->day` | oracle | |
| `mday_0` | `$dt->mday_0` | `$t->day - 1` | oracle | |
| `mdy` | `$dt->mdy('/')` | `$t->mdy('/')` | oracle | |
| `microsecond` | `$dt->microsecond` | `$t->microsecond` | oracle | |
| `millisecond` | `$dt->millisecond` | `$t->millisecond` | oracle | |
| `min` | `$dt->min` | `$t->minute` | oracle | |
| `minute` | `$dt->minute` | `$t->minute` | oracle | |
| `mjd` | `$dt->mjd` | `$t->mjd` | oracle | |
| `mon` | `$dt->mon` | `$t->month` | oracle | |
| `mon_0` | `$dt->mon_0` | `$t->month - 1` | oracle | |
| `month` | `$dt->month` | `$t->month` | oracle | |
| `month_0` | `$dt->month_0` | `$t->month - 1` | oracle | |
| `month_abbr` | `$dt->month_abbr` | `$t->month_abbr` | oracle | |
| `month_length` | `$dt->month_length` | `$t->days_in_month` | oracle | |
| `month_name` | `$dt->month_name` | `$t->month_name` | oracle | |
| `nanosecond` | `$dt->nanosecond` | `$t->nanosecond` | oracle | |
| `new` | `DateTime->new(year => 2026, month => 10, day => 15, hour => 9, time_zone => $zone)->epoch` | `$K->new(year => 2026, month => 10, day => 15, hour => 9, zone => $zone)->epoch` | oracle | |
| `now` | `DateTime->now` | `$K->now` | t/06-now.t | UTC, as DateTime's |
| `offset` | `$dt->offset` | `$t->offset` | oracle | |
| `quarter` | `$dt->quarter` | `$t->quarter` | oracle | |
| `quarter_0` | `$dt->quarter_0` | `$t->quarter - 1` | oracle | |
| `quarter_abbr` | `$dt->quarter_abbr` | `$t->quarter_abbr` | oracle | |
| `quarter_length` | `$dt->quarter_length` | `$t->days_in_quarter` | oracle | |
| `quarter_name` | `$dt->quarter_name` | `$t->quarter_name` | oracle | |
| `rfc3339` | `$dt->clone->truncate(to => 'second')->rfc3339` | `$t->offset ? $t->rfc3339(precision => 0) : $t->as_utc->rfc3339(precision => 0)` | oracle | DateTime writes `Z` for any zero offset; here `Z` is UTC's, and a zone at +00:00, such as London in winter, writes `+00:00`. Both are RFC 3339 |
| `sec` | `$dt->sec` | `$t->second` | oracle | |
| `second` | `$dt->second` | `$t->second` | oracle | |
| `secular_era` | `$dt->secular_era` | `$t->year > 0 ? 'CE' : 'BCE'` | oracle | |
| `set` | `$dt->clone->set(minute => 7, second => 0)->iso8601` | `$t->with(minute => 7, second => 0)->strftime('%FT%T')` | oracle utc | |
| `set_day` | `$dt->clone->set_day(1)->iso8601` | `$t->with(day => 1)->strftime('%FT%T')` | oracle utc | |
| `set_formatter` | `$dt->set_formatter($f)` | `$t->format('...')` | not provided (N2) | |
| `set_hour` | `$dt->clone->set_hour(5)->iso8601` | `$t->with(hour => 5)->strftime('%FT%T')` | oracle utc | |
| `set_locale` | `$dt->clone->set_locale('de')->month_name` | `$t->in_locale('de')->month_name` | oracle | |
| `set_minute` | `$dt->clone->set_minute(5)->iso8601` | `$t->with(minute => 5)->strftime('%FT%T')` | oracle utc | |
| `set_month` | `$dt->clone->set_day(1)->set_month(6)->iso8601` | `$t->with(day => 1, month => 6)->strftime('%FT%T')` | oracle utc | |
| `set_nanosecond` | `$dt->clone->set_nanosecond(5)->nanosecond` | `$t->with(nanosecond => 5)->nanosecond` | oracle | |
| `set_second` | `$dt->clone->set_second(5)->iso8601` | `$t->with(second => 5)->strftime('%FT%T')` | oracle utc | |
| `set_time_zone` | `$dt->clone->set_time_zone('Asia/Tokyo')->iso8601` | `$t->in_zone('Asia/Tokyo')->strftime('%FT%T')` | oracle | |
| `set_year` | `$dt->clone->set_day(1)->set_year(2030)->iso8601` | `$t->with(day => 1, year => 2030)->strftime('%FT%T')` | oracle utc | |
| `strftime` | `$dt->strftime('%a %d %b %Y %H:%M:%S %z %j %U %W %u %w %3N')` | `$t->strftime('%a %d %b %Y %H:%M:%S %z %j %U %W %u %w %3N')` | oracle | every conversion: xt/08-format-oracle.t |
| `stringify` | `$dt->stringify` | `"$t"` | t/12-overload.t | as `""` |
| `subtract` | `$dt->clone->subtract(days => 10)->iso8601` | `$t->minus(days => 10)->strftime('%FT%T')` | oracle utc | |
| `subtract_datetime` | `$dt->subtract_datetime($dt2)` | `$t->minus($t2)` | ruled K12 | as `-`; t/15-arith.t |
| `subtract_datetime_absolute` | `join ',', $dt->subtract_datetime_absolute($dt2)->in_units('seconds', 'nanoseconds')` | `join ',', $t->minus_absolute($t2)->in_units('seconds', 'nanoseconds')` | oracle | leap seconds counted by both |
| `subtract_duration` | `$dt->clone->subtract_duration(DateTime::Duration->new(hours => 30))->iso8601` | `$t->minus($D->new(hours => 30))->strftime('%FT%T')` | oracle utc | |
| `time` | `$dt->time` | `$t->time` | oracle | |
| `time_zone` | `$dt->time_zone->name` | `$t->zone_name` | oracle | a zone is a name (N11) |
| `time_zone_long_name` | `$dt->time_zone_long_name` | `$t->zone_name` | oracle | |
| `time_zone_short_name` | `$dt->time_zone_short_name` | `$t->zone_abbr` | oracle | |
| `today` | `DateTime->today` | `$K->today` | t/09-construct.t | |
| `truncate` | `$dt->clone->truncate(to => 'week')->iso8601` | `$t->truncate(to => 'week')->strftime('%FT%T')` | oracle utc | |
| `utc_rd_as_seconds` | `$dt->utc_rd_as_seconds` | `($t->utc_rd_values)[0] * 86400 + ($t->utc_rd_values)[1]` | oracle | |
| `utc_rd_values` | `join ',', $dt->utc_rd_values` | `join ',', $t->utc_rd_values` | oracle | |
| `utc_year` | | | struck: undocumented, used by DateTime::TimeZone | |
| `wday` | `$dt->wday` | `$t->day_of_week` | oracle | |
| `wday_0` | `$dt->wday_0` | `$t->day_of_week - 1` | oracle | |
| `week` | `join ',', $dt->week` | `join ',', $t->week_year, $t->week` | oracle | |
| `week_number` | `$dt->week_number` | `$t->week` | oracle | |
| `week_of_month` | `$dt->week_of_month` | `$t->week_of_month` | oracle | |
| `week_year` | `$dt->week_year` | `$t->week_year` | oracle | |
| `weekday_of_month` | `$dt->weekday_of_month` | `$t->format('F')` | oracle | |
| `year` | `$dt->year` | `$t->year` | oracle | |
| `year_length` | `$dt->year_length` | `$t->days_in_year` | oracle | |
| `year_with_christian_era` | `$dt->year_with_christian_era` | `($t->year > 0 ? $t->year : 1 - $t->year) . $t->era_abbr` | oracle | |
| `year_with_era` | `$dt->year_with_era` | `($t->year > 0 ? $t->year : 1 - $t->year) . $t->era_abbr` | oracle | |
| `year_with_secular_era` | `$dt->year_with_secular_era` | `($t->year > 0 ? $t->year . 'CE' : (1 - $t->year) . 'BCE')` | oracle | |
| `ymd` | `$dt->ymd('/')` | `$t->ymd('/')` | oracle | |

## Time::Piece 1.36

| method | theirs | Time::Keeper | check | note |
|---|---|---|---|---|
| `(""` | `"$tp"` | `$t->strftime('%a %b %e %H:%M:%S %Y')` | oracle | `"$t"` is RFC 3339 |
| `(+` | `($tp + 3600)->epoch` | `$t->plus(seconds => 3600)->epoch` | oracle | |
| `(-` | `$tp - $tp2` | `$t->epoch - $t2->epoch` | oracle | POSIX seconds, as Time::Piece counts them; `minus_absolute` counts leap seconds |
| `(<=>` | `$tp <=> $tp2` | `$t <=> $t2` | oracle | |
| `(cmp` | `$tp cmp $tp2` | `$t->strftime('%a %b %e %H:%M:%S %Y') cmp $t2->strftime('%a %b %e %H:%M:%S %Y')` | oracle | Time::Piece compares its strings, so Fri sorts before Mon; `cmp` here compares instants, as `<=>` does |
| `((` | | | struck: overload's bookkeeping | |
| `()` | | | struck: overload's bookkeeping | |
| `add` | `$tp->add(3600)->epoch` | `$t->plus(seconds => 3600)->epoch` | oracle | |
| `add_months` | `$tp->add_months(1)->epoch` | `$t->plus(months => 1)->epoch` | oracle | both wrap past the end of a month |
| `add_years` | `$tp->add_years(1)->epoch` | `$t->plus(years => 1)->epoch` | oracle | |
| `blessed` | | | struck: imported from Scalar::Util | |
| `bootstrap` | | | struck: XSLoader's | |
| `c_epoch` | | | struck: undocumented field index | |
| `c_hour` | | | struck: undocumented field index | |
| `c_isdst` | | | struck: undocumented field index | |
| `c_islocal` | | | struck: undocumented field index | |
| `c_mday` | | | struck: undocumented field index | |
| `c_min` | | | struck: undocumented field index | |
| `c_mon` | | | struck: undocumented field index | |
| `c_sec` | | | struck: undocumented field index | |
| `c_wday` | | | struck: undocumented field index | |
| `c_yday` | | | struck: undocumented field index | |
| `c_year` | | | struck: undocumented field index | |
| `carp` | | | struck: imported from Carp | |
| `cdate` | `$tp->cdate` | `$t->strftime('%a %b %e %H:%M:%S %Y')` | oracle | |
| `compare` | `$tp->compare($tp2, 0)` | `$K->compare($t, $t2)` | oracle | |
| `confess` | | | struck: imported from Carp | |
| `croak` | | | struck: imported from Carp | |
| `date` | `$tp->date` | `$t->date` | oracle | |
| `date_separator` | `Time::Piece::date_separator('/')` | `$t->ymd('/')` | not provided (N5) | a separator is given per call |
| `datetime` | `$tp->datetime` | `$t->strftime('%FT%T')` | oracle | |
| `day` | `$tp->day` | `$t->day_abbr` | oracle | |
| `day_list` | `join ' ', Time::Piece::day_list()` | `join ' ', ($L->names('en', 'days', 'abbreviated'))[6, 0 .. 5]` | oracle | Sunday first there, Monday first here; as a setter, N5 |
| `day_of_month` | `$tp->day_of_month` | `$t->day` | oracle | |
| `day_of_week` | `$tp->day_of_week` | `$t->day_of_week % 7` | oracle | |
| `day_of_year` | `$tp->day_of_year` | `$t->day_of_year - 1` | oracle | |
| `daylight_savings` | `$tp->daylight_savings ? 1 : 0` | `$t->is_dst` | oracle local | |
| `dmy` | `$tp->dmy('.')` | `$t->dmy('.')` | oracle | |
| `epoch` | `$tp->epoch` | `$t->epoch` | oracle | |
| `export` | | | struck: Exporter's | |
| `fullday` | `$tp->fullday` | `$t->day_name` | oracle | |
| `fullmonth` | `$tp->fullmonth` | `$t->month_name` | oracle | |
| `get_epochs` | | | struck: undocumented | |
| `gmtime` | `scalar(Time::Piece::gmtime($tp->epoch))->datetime` | `$K->from_epoch($t->epoch)->strftime('%FT%T')` | oracle | |
| `hms` | `$tp->hms('.')` | `$t->hms('.')` | oracle | |
| `hour` | `$tp->hour` | `$t->hour` | oracle | |
| `is_leap_year` | `$tp->is_leap_year ? 1 : 0` | `$t->is_leap_year` | oracle | |
| `isdst` | `$tp->isdst ? 1 : 0` | `$t->is_dst` | oracle local | |
| `julian_day` | `$tp->julian_day` | `$t->julian_day` | oracle | |
| `localtime` | `scalar(Time::Piece::localtime($tp->epoch))->datetime` | `$K->from_epoch($t->epoch, zone => 'local')->strftime('%FT%T')` | oracle local | Time::Piece's exported `localtime`, which replaces the core one, is not offered: ruled, own API only |
| `mday` | `$tp->mday` | `$t->day` | oracle | |
| `mdy` | `$tp->mdy('.')` | `$t->mdy('.')` | oracle | |
| `min` | `$tp->min` | `$t->minute` | oracle | |
| `minute` | `$tp->minute` | `$t->minute` | oracle | |
| `mjd` | `$tp->mjd` | `$t->mjd` | oracle | |
| `mon` | `$tp->mon` | `$t->month` | oracle | |
| `mon_list` | `join ' ', Time::Piece::mon_list()` | `join ' ', $L->names('en', 'months', 'abbreviated')` | oracle | as a setter, N5 |
| `monname` | `$tp->monname` | `$t->month_abbr` | oracle | |
| `month` | `$tp->month` | `$t->month_abbr` | oracle | |
| `month_last_day` | `$tp->month_last_day` | `$t->days_in_month` | oracle | |
| `new` | `Time::Piece->new($tp->epoch)->epoch` | `$K->from_epoch($t->epoch)->epoch` | oracle | |
| `parse` | | | struck: undocumented, strptime's helper | |
| `sec` | `$tp->sec` | `$t->second` | oracle | |
| `second` | `$tp->second` | `$t->second` | oracle | |
| `str_compare` | `$tp->str_compare($tp2, 0)` | `$t->strftime('%a %b %e %H:%M:%S %Y') cmp $t2->strftime('%a %b %e %H:%M:%S %Y')` | oracle | as `cmp` |
| `strftime` | `$tp->strftime('%Y-%m-%d %H:%M:%S %a %b %j %U')` | `$t->strftime('%Y-%m-%d %H:%M:%S %a %b %j %U')` | oracle | every conversion: xt/08-format-oracle.t |
| `strptime` | `Time::Piece->strptime($tp->strftime('%d/%m/%Y %H:%M'), '%d/%m/%Y %H:%M')->epoch` | `$K->strptime($t->strftime('%d/%m/%Y %H:%M'), '%d/%m/%Y %H:%M')->epoch` | oracle | 24,000 strings: xt/09-parse-oracle.t |
| `subtract` | `$tp->subtract(3600)->epoch` | `$t->minus(seconds => 3600)->epoch` | oracle | |
| `time` | `$tp->time` | `$t->time` | oracle | |
| `time_separator` | `Time::Piece::time_separator('.')` | `$t->hms('.')` | not provided (N5) | a separator is given per call |
| `timegm` | | | struck: imported from Time::Local | |
| `timelocal` | | | struck: imported from Time::Local | |
| `truncate` | `$tp->truncate(to => 'month')->epoch` | `$t->truncate(to => 'month')->epoch` | oracle | |
| `tzoffset` | `0 + $tp->tzoffset` | `$t->offset` | oracle local | |
| `use_locale` | `Time::Piece->use_locale` | `$t->in_locale('fr')` | not provided (N5) | names come from the value's locale |
| `wday` | `$tp->wday` | `$t->day_of_week % 7 + 1` | oracle | |
| `wdayname` | `$tp->wdayname` | `$t->day_abbr` | oracle | |
| `week` | `$tp->week` | `$t->week` | oracle | |
| `yday` | `$tp->yday` | `$t->day_of_year - 1` | oracle | |
| `year` | `$tp->year` | `$t->year` | oracle | |
| `ymd` | `$tp->ymd('.')` | `$t->ymd('.')` | oracle | |
| `yy` | `$tp->yy` | `$t->year % 100` | oracle | |

## Time::Seconds 1.36

| method | theirs | Time::Keeper | check | note |
|---|---|---|---|---|
| `(""` | `"$ts"` | `$s->total_seconds` | oracle | `"$s"` is ISO 8601: `PT90061S` |
| `(+` | `0 + ($ts + 60)` | `($s + $D->new(seconds => 60))->total_seconds` | oracle | |
| `(+=` | `do { my $x = $ts; $x += 60; 0 + $x }` | `($s + $D->new(seconds => 60))->total_seconds` | oracle | a new duration (K1) |
| `(-` | `0 + ($ts - 60)` | `($s - $D->new(seconds => 60))->total_seconds` | oracle | |
| `(-=` | `do { my $x = $ts; $x -= 60; 0 + $x }` | `($s - $D->new(seconds => 60))->total_seconds` | oracle | a new duration (K1) |
| `(0+` | `0 + $ts` | `$s->total_seconds` | not provided (N9) | |
| `(<=>` | `$ts <=> 100` | `$s->total_seconds <=> 100` | oracle | durations compare with each other too: `$s <=> $D->new(...)` |
| `(=` | | | ruled K1 | the copy constructor of `+=`; durations never change |
| `((` | | | struck: overload's bookkeeping | |
| `()` | | | struck: overload's bookkeeping | |
| `add` | `0 + $ts->add(60)` | `$s->plus($D->new(seconds => 60))->total_seconds` | oracle | |
| `add_to` | | | struck: `+=`'s implementation | |
| `compare` | `$ts->compare(100, 0)` | `$s->total_seconds <=> 100` | oracle | |
| `copy` | | | ruled K1 | |
| `cs_mon` | | | struck: undocumented | |
| `cs_sec` | | | struck: undocumented | |
| `days` | `$ts->days` | `$s->total_seconds / 86400` | oracle | |
| `financial_months` | `$ts->financial_months` | `$s->total_seconds / 2592000` | oracle | |
| `hours` | `$ts->hours` | `$s->total_seconds / 3600` | oracle | |
| `minutes` | `$ts->minutes` | `$s->total_seconds / 60` | oracle | |
| `months` | `$ts->months` | `$s->total_seconds / 2629744` | oracle | Time::Seconds' average month |
| `new` | `0 + Time::Seconds->new(90061)` | `$D->from_seconds(90061)->total_seconds` | oracle | |
| `pretty` | `$ts->pretty` | `$s->iso8601` | not provided (N8) | |
| `seconds` | `$ts->seconds` | `$s->total_seconds` | oracle | |
| `subtract` | `0 + $ts->subtract(60)` | `$s->minus($D->new(seconds => 60))->total_seconds` | oracle | |
| `subtract_from` | | | struck: `-=`'s implementation | |
| `weeks` | `$ts->weeks` | `$s->total_seconds / 604800` | oracle | |
| `years` | `$ts->years` | `$s->total_seconds / 31556930` | oracle | Time::Seconds' year |

## DateTime::Duration 1.66

| method | theirs | Time::Keeper | check | note |
|---|---|---|---|---|
| `(*` | `P($dd * 3)` | `P($d * 3)` | oracle | |
| `(+` | `P($dd + $dd2)` | `P($d + $d2)` | oracle | |
| `(-` | `P($dd - $dd2)` | `P($d - $d2)` | oracle | |
| `(<=>` | `$dd <=> $dd2` | `$d <=> $d2` | t/14-duration.t | DateTime's dies: a duration of months has no fixed length. Here it compares as `compare` does, from a base |
| `(cmp` | `$dd cmp $dd2` | `$d <=> $d2` | t/14-duration.t | as `<=>` |
| `((` | | | struck: overload's bookkeeping | |
| `()` | | | struck: overload's bookkeeping | |
| `add` | `P($dd->clone->add(days => 2))` | `P($d->plus($D->new(days => 2)))` | oracle | |
| `add_duration` | `P($dd->clone->add_duration($dd2))` | `P($d->plus($d2))` | oracle | |
| `calendar_duration` | `P($dd->calendar_duration)` | `P($d->calendar_duration)` | oracle | |
| `clock_duration` | `P($dd->clock_duration)` | `P($d->clock_duration)` | oracle | |
| `clone` | `$dd->clone` | `$d` | ruled K1 | |
| `compare` | `DateTime::Duration->compare($dd, $dd2, $dt)` | `$D->compare($d, $d2, $t)` | ruled K12 | both compare the two sums from the base; the sums differ where K12 says (months are added first here), and so in 18 of 20,000 random pairs does the answer. t/14-duration.t |
| `days` | `$dd->days` | `$d->days` | oracle | |
| `delta_days` | `$dd->delta_days` | `+{ $d->deltas }->{days}` | oracle | |
| `delta_minutes` | `$dd->delta_minutes` | `+{ $d->deltas }->{minutes}` | oracle | |
| `delta_months` | `$dd->delta_months` | `+{ $d->deltas }->{months}` | oracle | |
| `delta_nanoseconds` | `$dd->delta_nanoseconds` | `+{ $d->deltas }->{nanoseconds}` | oracle | |
| `delta_seconds` | `$dd->delta_seconds` | `+{ $d->deltas }->{seconds}` | oracle | |
| `deltas` | `join ',', map { my %h = $dd->deltas; "$_=$h{$_}" } sort keys %{ { $dd->deltas } }` | `join ',', map { my %h = $d->deltas; "$_=$h{$_}" } sort keys %{ { $d->deltas } }` | oracle | |
| `end_of_month_mode` | `$dd->end_of_month_mode` | `$d->end_of_month` | oracle | |
| `hours` | `$dd->hours` | `$d->hours` | oracle | |
| `in_units` | `join ',', $dd->in_units('years', 'months', 'weeks', 'days', 'hours', 'minutes')` | `join ',', $d->in_units('years', 'months', 'weeks', 'days', 'hours', 'minutes')` | oracle | |
| `inverse` | `P($dd->inverse)` | `P($d->inverse)` | oracle | |
| `is_limit_mode` | `$dd->is_limit_mode ? 1 : 0` | `$d->end_of_month eq 'limit' ? 1 : 0` | oracle | |
| `is_negative` | `$dd->is_negative ? 1 : 0` | `$d->is_negative ? 1 : 0` | oracle | |
| `is_positive` | `$dd->is_positive ? 1 : 0` | `$d->is_positive ? 1 : 0` | oracle | |
| `is_preserve_mode` | `$dd->is_preserve_mode ? 1 : 0` | `$d->end_of_month eq 'preserve' ? 1 : 0` | oracle | |
| `is_wrap_mode` | `$dd->is_wrap_mode ? 1 : 0` | `$d->end_of_month eq 'wrap' ? 1 : 0` | oracle | |
| `is_zero` | `$dd->is_zero ? 1 : 0` | `$d->is_zero ? 1 : 0` | oracle | |
| `minutes` | `$dd->minutes` | `$d->minutes` | oracle | |
| `months` | `$dd->months` | `$d->months` | oracle | |
| `multiply` | `P($dd->clone->multiply(2))` | `P($d->multiply(2))` | oracle | |
| `nanoseconds` | `$dd->nanoseconds` | `$d->nanoseconds` | oracle | |
| `new` | `P(DateTime::Duration->new(hours => 25, seconds => 90))` | `P($D->new(hours => 25, seconds => 90))` | oracle | |
| `seconds` | `$dd->seconds` | `$d->seconds` | oracle | |
| `subtract` | `P($dd->clone->subtract(days => 2))` | `P($d->minus($D->new(days => 2)))` | oracle | |
| `subtract_duration` | `P($dd->clone->subtract_duration($dd2))` | `P($d->minus($d2))` | oracle | |
| `weeks` | `$dd->weeks` | `$d->weeks` | oracle | |
| `years` | `$dd->years` | `$d->years` | oracle | |

## DateTime::TimeZone 2.66

A zone is a name here, not an object (N11): a value's zone is `$t->zone_name`, and
Time::Keeper::Zone answers questions of zones by name.

| method | theirs | Time::Keeper | check | note |
|---|---|---|---|---|
| `STORABLE_freeze` | | | not provided (N11) | a value freezes its zone by name: t/13-handles.t |
| `STORABLE_thaw` | | | not provided (N11) | |
| `all_names` | `DateTime::TimeZone->all_names` | `$Z->names` | ../Time-Keeper-Zone/t/04-surface.t | the two carry different tzdata releases |
| `categories` | `DateTime::TimeZone->categories` | `my %c; $c{ (split m{/})[0] }++ for grep { m{/} } $Z->names; sort keys %c` | ../Time-Keeper-Zone/t/04-surface.t | |
| `category` | `$tz->category // ''` | `$t->zone_name =~ m{^([^/]+)/} ? $1 : ''` | oracle | |
| `countries` | `scalar(grep { $_ ne 'uk' } DateTime::TimeZone->countries)` | `scalar(() = $Z->countries) / 2` | oracle | given as pairs of code and name; DateTime::TimeZone also lists `uk`, which is not an ISO 3166 code, beside `gb` |
| `has_dst_changes` | `$tz->has_dst_changes` | | not provided (N10) | |
| `is_dst_for_datetime` | `$tz->is_dst_for_datetime($dt)` | `$t->is_dst` | oracle | |
| `is_floating` | `$tz->is_floating` | `$t->is_floating` | oracle | |
| `is_olson` | `$tz->is_olson ? 1 : 0` | `$t->zone_name =~ m{/} ? 1 : 0` | oracle | |
| `is_utc` | `$tz->is_utc ? 1 : 0` | `$t->is_utc ? 1 : 0` | oracle | |
| `is_valid_name` | `DateTime::TimeZone->is_valid_name($zone) ? 1 : 0` | `$Z->is_valid($zone) ? 1 : 0` | oracle | |
| `links` | `DateTime::TimeZone->links` | `$Z->links` | ../Time-Keeper-Zone/t/04-surface.t | |
| `max_span` | | | struck: undocumented constant | |
| `name` | `$tz->name` | `$t->zone_name` | oracle | |
| `names_in_category` | `join ',', sort DateTime::TimeZone->names_in_category('Australia')` | `join ',', sort map { m{^Australia/(.+)} ? $1 : () } $Z->names` | oracle | |
| `names_in_country` | `join ',', sort DateTime::TimeZone->names_in_country('AU')` | `join ',', sort $Z->zones_for_country('AU')` | oracle | |
| `new` | `DateTime::TimeZone->new(name => $zone)->name` | `$Z->name($zone)` | oracle | |
| `offset_as_seconds` | `DateTime::TimeZone->offset_as_seconds('-03:30')` | `$K->now(zone => '-03:30')->offset` | oracle | |
| `offset_as_string` | `DateTime::TimeZone->offset_as_string(-12600)` | `$K->now(zone => '-03:30')->strftime('%z')` | oracle | |
| `offset_for_datetime` | `$tz->offset_for_datetime($dt)` | `$t->offset` | oracle | |
| `offset_for_local_datetime` | `$tz->offset_for_local_datetime($dt)` | `$t->with(second => $t->second)->offset` | oracle utc | in an overlap the earlier reading here (K3) |
| `short_name_for_datetime` | `$tz->short_name_for_datetime($dt)` | `$t->zone_abbr` | oracle | |

## DateTime::Locale 1.45

| method | theirs | Time::Keeper | check | note |
|---|---|---|---|---|
| `add_aliases` | `DateTime::Locale->add_aliases(...)` | | not provided (N6) | |
| `codes` | `DateTime::Locale->codes` | `$L->codes` | xt/10-locale-oracle.t | every code there is one here |
| `ids` | `DateTime::Locale->ids` | `$L->codes` | xt/10-locale-oracle.t | |
| `load` | `DateTime::Locale->load($code)->code` | `$L->code($code)` | oracle | |
| `names` | `DateTime::Locale->names` | `map { $L->name($_) } $L->codes` | t/22-locale.t | CLDR's pattern, `French (Canada)`, not `French Canada` |
| `native_names` | `DateTime::Locale->native_names` | `map { $L->native_name($_) } $L->codes` | t/22-locale.t | |
| `register` | `DateTime::Locale->register(...)` | | not provided (N6) | |
| `register_from_data` | `DateTime::Locale->register_from_data(...)` | | not provided (N6) | |
| `remove_alias` | `DateTime::Locale->remove_alias(...)` | | not provided (N6) | |

## DateTime::Locale::FromData 1.45

A locale is a code here, not an object (N11): `Time::Keeper::Locale` answers for a code.

| method | theirs | Time::Keeper | check | note |
|---|---|---|---|---|
| `STORABLE_freeze` | | | not provided (N11) | a value freezes its locale by code: t/22-locale.t |
| `STORABLE_thaw` | | | not provided (N11) | |
| `am_pm_abbreviated` | `$loc->am_pm_abbreviated` | `[$L->names($code, 'am_pm', 'abbreviated')]` | oracle | |
| `available_formats` | `$loc->available_formats` | `keys %{ $L->available_formats($code) }` | xt/10-locale-oracle.t | DateTime::Locale leaves out the `-alt-` keys |
| `code` | `$loc->code` | `$L->code($code)` | oracle | |
| `date_format_default` | | | struck: deprecated in DateTime::Locale | |
| `date_format_full` | `$loc->date_format_full` | `($L->formats($code, 'date'))[0]` | oracle | |
| `date_format_long` | `$loc->date_format_long` | `($L->formats($code, 'date'))[1]` | oracle | |
| `date_format_medium` | `$loc->date_format_medium` | `($L->formats($code, 'date'))[2]` | oracle | |
| `date_format_short` | `$loc->date_format_short` | `($L->formats($code, 'date'))[3]` | oracle | |
| `date_formats` | `join ',', map { $loc->date_formats->{$_} } qw(full long medium short)` | `join ',', $L->formats($code, 'date')` | oracle | |
| `datetime_format` | `$loc->datetime_format` | `($L->formats($code, 'datetime'))[2]` | oracle | |
| `datetime_format_default` | | | struck: deprecated in DateTime::Locale | |
| `datetime_format_full` | `$loc->datetime_format_full` | `($L->formats($code, 'datetime'))[0] =~ s/\{1\}/($L->formats($code, 'date'))[0]/er =~ s/\{0\}/($L->formats($code, 'time'))[0]/er` | oracle | |
| `datetime_format_long` | `$loc->datetime_format_long` | `($L->formats($code, 'datetime'))[1] =~ s/\{1\}/($L->formats($code, 'date'))[1]/er =~ s/\{0\}/($L->formats($code, 'time'))[1]/er` | oracle | |
| `datetime_format_medium` | `$loc->datetime_format_medium` | `($L->formats($code, 'datetime'))[2] =~ s/\{1\}/($L->formats($code, 'date'))[2]/er =~ s/\{0\}/($L->formats($code, 'time'))[2]/er` | oracle | |
| `datetime_format_short` | `$loc->datetime_format_short` | `($L->formats($code, 'datetime'))[3] =~ s/\{1\}/($L->formats($code, 'date'))[3]/er =~ s/\{0\}/($L->formats($code, 'time'))[3]/er` | oracle | |
| `day_format_abbreviated` | `$loc->day_format_abbreviated` | `[$L->names($code, 'days', 'abbreviated')]` | oracle | |
| `day_format_narrow` | `$loc->day_format_narrow` | `[$L->names($code, 'days', 'narrow')]` | oracle | |
| `day_format_wide` | `$loc->day_format_wide` | `[$L->names($code, 'days', 'wide')]` | oracle | |
| `day_stand_alone_abbreviated` | `$loc->day_stand_alone_abbreviated` | `[$L->names($code, 'days', 'abbreviated', 'stand-alone')]` | oracle | |
| `day_stand_alone_narrow` | `$loc->day_stand_alone_narrow` | `[$L->names($code, 'days', 'narrow', 'stand-alone')]` | oracle | |
| `day_stand_alone_wide` | `$loc->day_stand_alone_wide` | `[$L->names($code, 'days', 'wide', 'stand-alone')]` | oracle | |
| `default_date_format_length` | | | struck: deprecated in DateTime::Locale | |
| `default_time_format_length` | | | struck: deprecated in DateTime::Locale | |
| `era_abbreviated` | `$loc->era_abbreviated` | `[$L->names($code, 'eras', 'abbreviated')]` | oracle | |
| `era_narrow` | `$loc->era_narrow` | `[$L->names($code, 'eras', 'narrow')]` | oracle | |
| `era_wide` | `$loc->era_wide` | `[$L->names($code, 'eras', 'wide')]` | oracle | |
| `first_day_of_week` | `$loc->first_day_of_week` | `$L->first_day_of_week($code)` | t/22-locale.t | as `local_day_of_week`: 7 for `en` here, 1 there; the same for the others |
| `format_for` | `$loc->format_for('yMMMd')` | `$L->available_formats($code)->{yMMMd}` | oracle | |
| `glibc_date_1_format` | | | not provided (N7) | |
| `glibc_date_format` | | | not provided (N7) | |
| `glibc_datetime_format` | | | not provided (N7) | |
| `glibc_time_12_format` | | | not provided (N7) | |
| `glibc_time_format` | | | not provided (N7) | |
| `id` | `$loc->id` | `$L->code($code)` | oracle | |
| `language` | `$loc->language` | `$L->parts($code)->{language_name}` | oracle | |
| `language_code` | `$loc->language_code` | `$L->parts($code)->{language}` | oracle | |
| `language_id` | `$loc->language_id` | `$L->parts($code)->{language}` | oracle | |
| `locale_data` | `$loc->locale_data` | | not provided (N11) | |
| `month_format_abbreviated` | `$loc->month_format_abbreviated` | `[$L->names($code, 'months', 'abbreviated')]` | oracle | |
| `month_format_narrow` | `$loc->month_format_narrow` | `[$L->names($code, 'months', 'narrow')]` | oracle | |
| `month_format_wide` | `$loc->month_format_wide` | `[$L->names($code, 'months', 'wide')]` | oracle | |
| `month_stand_alone_abbreviated` | `$loc->month_stand_alone_abbreviated` | `[$L->names($code, 'months', 'abbreviated', 'stand-alone')]` | oracle | |
| `month_stand_alone_narrow` | `$loc->month_stand_alone_narrow` | `[$L->names($code, 'months', 'narrow', 'stand-alone')]` | oracle | |
| `month_stand_alone_wide` | `$loc->month_stand_alone_wide` | `[$L->names($code, 'months', 'wide', 'stand-alone')]` | oracle | |
| `name` | `$loc->name` | `$L->name($code)` | t/22-locale.t | CLDR's pattern, `French (Canada)`, not `French Canada` |
| `native_language` | `$loc->native_language` | `$L->parts($code)->{native_language_name}` | oracle | |
| `native_name` | `$loc->native_name` | `$L->native_name($code)` | t/22-locale.t | as `name` |
| `native_script` | `$loc->native_script` | `$L->parts($code)->{native_script_name}` | oracle | |
| `native_territory` | `$loc->native_territory` | `$L->parts($code)->{native_territory_name}` | oracle | |
| `native_variant` | `$loc->native_variant` | `$L->parts($code)->{native_variant_name}` | oracle | |
| `new` | | | struck: DateTime::Locale->load makes them | |
| `prefers_24_hour_time` | `$loc->prefers_24_hour_time ? 1 : 0` | `$L->prefers_24_hour_time($code) ? 1 : 0` | oracle | |
| `quarter_format_abbreviated` | `$loc->quarter_format_abbreviated` | `[$L->names($code, 'quarters', 'abbreviated')]` | oracle | |
| `quarter_format_narrow` | `$loc->quarter_format_narrow` | `[$L->names($code, 'quarters', 'narrow')]` | oracle | |
| `quarter_format_wide` | `$loc->quarter_format_wide` | `[$L->names($code, 'quarters', 'wide')]` | oracle | |
| `quarter_stand_alone_abbreviated` | `$loc->quarter_stand_alone_abbreviated` | `[$L->names($code, 'quarters', 'abbreviated', 'stand-alone')]` | oracle | |
| `quarter_stand_alone_narrow` | `$loc->quarter_stand_alone_narrow` | `[$L->names($code, 'quarters', 'narrow', 'stand-alone')]` | oracle | |
| `quarter_stand_alone_wide` | `$loc->quarter_stand_alone_wide` | `[$L->names($code, 'quarters', 'wide', 'stand-alone')]` | oracle | |
| `script` | `$loc->script` | `$L->parts($code)->{script_name}` | oracle | |
| `script_code` | `$loc->script_code` | `$L->parts($code)->{script}` | oracle | |
| `script_id` | `$loc->script_id` | `$L->parts($code)->{script}` | oracle | |
| `set_default_date_format_length` | | | struck: deprecated in DateTime::Locale | |
| `set_default_time_format_length` | | | struck: deprecated in DateTime::Locale | |
| `territory` | `$loc->territory` | `$L->parts($code)->{territory_name}` | oracle | |
| `territory_code` | `$loc->territory_code` | `$L->parts($code)->{territory}` | oracle | |
| `territory_id` | `$loc->territory_id` | `$L->parts($code)->{territory}` | oracle | |
| `time_format_default` | | | struck: deprecated in DateTime::Locale | |
| `time_format_full` | `$loc->time_format_full` | `($L->formats($code, 'time'))[0]` | oracle | |
| `time_format_long` | `$loc->time_format_long` | `($L->formats($code, 'time'))[1]` | oracle | |
| `time_format_medium` | `$loc->time_format_medium` | `($L->formats($code, 'time'))[2]` | oracle | |
| `time_format_short` | `$loc->time_format_short` | `($L->formats($code, 'time'))[3]` | oracle | |
| `time_formats` | `join ',', map { $loc->time_formats->{$_} } qw(full long medium short)` | `join ',', $L->formats($code, 'time')` | oracle | |
| `variant` | `$loc->variant` | `$L->parts($code)->{variant_name}` | oracle | |
| `variant_code` | `$loc->variant_code` | `$L->parts($code)->{variant}` | oracle | |
| `variant_id` | `$loc->variant_id` | `$L->parts($code)->{variant}` | oracle | |
| `version` | `$loc->version` | `$L->cldr_version` | t/22-locale.t | CLDR 48.2.3 here, 47 there |

## DateTime::Infinite 1.66

Time::Keeper has no infinite values (N3): `$K->max` and `$K->min` are the last and first
instants, and compare as any value does.

| method | theirs | Time::Keeper | check | note |
|---|---|---|---|---|
| `STORABLE_freeze` | | | not provided (N3) | |
| `STORABLE_thaw` | | | not provided (N3) | |
| `datetime` | | | not provided (N3) | |
| `dmy` | | | not provided (N3) | |
| `hms` | | | not provided (N3) | |
| `hour_12` | | | not provided (N3) | |
| `hour_12_0` | | | not provided (N3) | |
| `is_finite` | | | not provided (N3) | |
| `is_infinite` | | | not provided (N3) | |
| `mdy` | | | not provided (N3) | |
| `set` | | | not provided (N3) | |
| `set_time_zone` | | | not provided (N3) | |
| `stringify` | | | not provided (N3) | |
| `truncate` | | | not provided (N3) | |
| `ymd` | | | not provided (N3) | |

## Not provided

Each was accepted by the owner on 16 October 2026; `xt/11-parity.t` fails on any reason that
is not.

| | what | why |
|---|---|---|
| N1 | DateTime's `DefaultLocale` | Process-wide state that every value made anywhere would pick up. A value's locale is given where it is made, or changed with `in_locale`. Accepted by the owner, 16 October 2026. |
| N2 | DateTime's `formatter` and `set_formatter` | An object held in each value, called when it is stringified. A value is one packed struct (K8) with no room for one; `"$t"` is always RFC 3339, and `format` or a formatter's own method gives any other form. Accepted by the owner, 16 October 2026. |
| N3 | DateTime::Infinite, `is_finite`, `is_infinite` | Infinite values break every accessor (DateTime's give `Inf` or nonsense). `$K->max` and `$K->min`, a billion years out, sort after and before every value. Accepted by the owner, 16 October 2026. |
| N4 | DateTime's `duration_class` | A hook for subclasses to choose their durations' class. Arithmetic here gives Time::Keeper::Duration. Accepted by the owner, 16 October 2026. |
| N5 | Time::Piece's `date_separator`, `time_separator`, `use_locale`, and `day_list` and `mon_list` as setters | Process-wide settings. Separators are given per call; names come from the value's locale. Accepted by the owner, 16 October 2026. |
| N6 | DateTime::Locale's `register`, `register_from_data`, `add_aliases` and `remove_alias` | Locales made at run time. The data is compiled from one CLDR release, checked against it (xt/10), and read from one file. Accepted by the owner, 16 October 2026. |
| N7 | DateTime::Locale's `glibc_*` formats | The C library's per-locale formats, which are not CLDR's. `strftime`'s `%c`, `%x` and `%X` use the locale's CLDR formats. Accepted by the owner, 16 October 2026. |
| N8 | Time::Seconds' `pretty` | English prose only (`1 day, 1 hour, 1 minute, 1 second`). `iso8601` and `in_units` give the parts. Accepted by the owner, 16 October 2026. |
| N9 | Time::Seconds' numeric overloading, `0+` | A duration of months has no fixed number of seconds, so a duration is not a number. `total_seconds` gives one, and dies for months and days. Accepted by the owner, 16 October 2026. |
| N10 | DateTime::TimeZone's `has_dst_changes` | Whether a zone ever kept daylight time. Not asked for by anything in the ecosystem; `is_dst` answers at an instant. Accepted by the owner, 16 October 2026. |
| N11 | Zone and locale objects, and their freezing and raw data (`locale_data`) | A zone is a name and a locale a code, interned in the C core (K5). Time::Keeper::Zone and Time::Keeper::Locale answer for them; a value freezes them by name. Accepted by the owner, 16 October 2026. |

## What neither has

- RFC 9557 (`rfc9557`, and its `[Zone]` suffix in `parse`) and RFC 9110's `http_date`.
- ISO 8601 intervals (`parse_interval`), week and ordinal dates and durations in `parse`.
- `round`, and `truncate` to a quarter.
- glibc's `strftime` flags (`%-d`, `%_d`, `%^a`, a width) and `%O`'s local digits.
- CLDR's zone names (`z`, `v`, `V` and their lengths), day periods (`b`, `B`) and the
  locale's weeks in `format`, and all of them read back by `parse_cldr`.
- Digits of every script, written in the locales that use them and read in any.
- Arithmetic that round-trips (K12), and `try_` parsers that leave `$@` alone.
- Values that never change (K1), and a locale and a zone that cost 16 bits each.
