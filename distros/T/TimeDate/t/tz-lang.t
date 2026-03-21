use Test::More tests => 10;
use Date::Language;

# Tests for language-specific timezone abbreviation translation (issue #1 / RT#52878)
# When using %Z format with a language object, timezone abbreviations should be
# translated to the language's local equivalents if the language defines a %TZ mapping.

my $german  = Date::Language->new('German');
my $english = Date::Language->new('English');

# Fixed timestamp: 2009-01-01 00:00:00 UTC (standard time, no DST)
my $t = 1230768000;

# English should return standard English abbreviations unchanged
is( $english->time2str('%Z', $t, 'CET'),  'CET',  'English: CET stays CET'  );
is( $english->time2str('%Z', $t, 'CEST'), 'CEST', 'English: CEST stays CEST' );
is( $english->time2str('%Z', $t, 'GMT'),  'GMT',  'English: GMT stays GMT'   );

# German should translate CET → MEZ and CEST → MESZ
is( $german->time2str('%Z', $t, 'CET'),  'MEZ',  'German: CET → MEZ'  );
is( $german->time2str('%Z', $t, 'CEST'), 'MESZ', 'German: CEST → MESZ' );

# German: timezones without a translation should pass through unchanged
is( $german->time2str('%Z', $t, 'GMT'),  'GMT',  'German: GMT passes through (no translation defined)' );
is( $german->time2str('%Z', $t, 'UTC'),  'UTC',  'German: UTC passes through (no translation defined)' );

# German: other European timezone translations
is( $german->time2str('%Z', $t, 'EET'),  'OEZ',  'German: EET → OEZ'  );
is( $german->time2str('%Z', $t, 'EEST'), 'OESZ', 'German: EEST → OESZ' );
is( $german->time2str('%Z', $t, 'WET'),  'WEZ',  'German: WET → WEZ'  );
