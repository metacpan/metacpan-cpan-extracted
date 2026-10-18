#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
sub t { $K->new(@_) }
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}

# 12 to 18 October 2026 is Monday to Sunday.
my %weekend = (
    'en-US' => [6, 7], en => [6, 7], 'fr-CA' => [6, 7], 'ar-EG' => [5, 6], he => [5, 6], 'fa-AF' => [4, 5],
    'hi-IN' => [7, 7], 'ar-SA' => [5, 6], ja => [6, 7],
);
for my $loc (sort keys %weekend) {
    my ($ws, $we) = @{ $weekend{$loc} };
    for my $d (12 .. 18) {
        my $t = t(year => 2026, month => 10, day => $d, hour => 9, locale => $loc);
        my $dow = $t->day_of_week;
        my $want = $ws <= $we ? ($dow >= $ws && $dow <= $we) : ($dow >= $ws || $dow <= $we);
        is(!!$t->is_weekend, !!$want, "$loc: day $dow is " . ($want ? 'the weekend' : 'a weekday'));
        is(!!$t->is_weekday, !$want, "and is_weekday says the opposite");
    }
}
is(t(year => 2026, month => 10, day => 17)->is_weekend, 1, 'English by default: a Saturday is the weekend');
is(t(year => 2026, month => 10, day => 16)->is_weekend, 0, 'and a Friday is not');
is(t(year => 2026, month => 10, day => 16, locale => 'ar-EG')->is_weekend, 1, 'but in Egypt it is');
is(t(year => 2026, month => 10, day => 18, locale => 'ar-EG')->is_weekend, 0, 'and Sunday is not');
is(t(year => 2026, month => 10, day => 18, locale => 'hi-IN')->is_weekend, 1, 'India: Sunday alone');
is(t(year => 2026, month => 10, day => 17, locale => 'hi-IN')->is_weekend, 0, 'Saturday is a weekday there');
is(t(year => 2026, month => 10, day => 17, zone => 'floating', locale => 'en')->is_weekend, 1, 'floating time has a day of the week too');
is(t(year => 2026, month => 10, day => 17, hour => 23, zone => 'Asia/Tokyo')->in_zone('UTC')->is_weekend, 1,
   'by the wall clock of the value\'s zone: Saturday 14:00 UTC');
is(t(year => 2026, month => 10, day => 18, hour => 2, zone => 'Asia/Tokyo')->in_zone('UTC')->is_weekend, 1,
   'Sunday 02:00 Tokyo is Saturday 17:00 UTC: both weekend');
dies_like(sub { t(year => 2026)->is_weekend(1) }, qr/this accessor takes no arguments/, 'no arguments');

done_testing;
