print "1..5\n";

use Data::Dumper;
use WWW::WCAP qw(login do_request parse_ical logout);
use Benchmark::Timer;		# Performance measure

print "ok 1\n";

my $timer = Benchmark::Timer->new(skip => 0);
my $user = 'youruser';
my $pass = 'yourpass';
my $ref;

# From now
my ($min,$hh,$dd,$mm,$yy) = (localtime)[1,2,3,4,5];
$mm++; $yy += 1900; # adjust to real values
my $range_start = sprintf("%4.4d%2.2d%2.2dT%2.2d%2.2d00", $yy, $mm, $dd, $hh, $min);

# until tomorrow
($min,$hh,$dd,$mm,$yy) = (localtime(time + 3600 * 24))[1,2,3,4,5];
$mm++; $yy += 1900; # adjust to real values
my $range_end = sprintf("%4.4d%2.2d%2.2dT%2.2d%2.2d00", $yy, $mm, $dd, $hh, $min);

$timer->start("TEST>> Logging in: $user");
my $id = &login($user,$pass);
print "not " unless $id && $id ne '';
print "ok 2\n";
print Dumper($id);
$timer->stop;

$timer->start("TEST>> Getting calendar for: $user");
$ref = &do_request($id,'fetchcomponents_by_range.wcap',
	'uid=' . $user,
	'dtstart=' . $range_start, 'dtend=' . $range_end,
);
print "not " unless $ref && $ref->{status};
print "ok 3\n";
print Dumper($ref);
$timer->stop;

$timer->start("TEST>> Displaying calendar for: $user");
$ref = &parse_ical($ref->{content});
print "not " unless $ref && $ref->{status};
print "ok 4\n";
print Dumper($ref);
$timer->stop;

$timer->start("TEST>> Logging out: $user");
$ref = &logout($id);
print "not " unless $ref && $ref->{status};
print "ok 5\n";
print Dumper($ref);
$timer->stop;

print $timer->report;
