use Test;
use Time::Timecode;
use TestHelper;

BEGIN { plan tests => 26 }

# Parse non-dropframe
my $tc = Time::Timecode->new('01:02:03:04');
hmsf_ok($tc, 1, 2, 3, 4);
ok(!$tc->is_dropframe);

# Parse with dropframe frame delimiters
$tc = Time::Timecode->new('00:01:00.02');
hmsf_ok($tc, 0, 1, 0, 2);
ok($tc->is_dropframe);

$tc = Time::Timecode->new('10:00:00;22');
hmsf_ok($tc, 10, 0, 0, 22);
ok($tc->is_dropframe);

# Normally a dropframe frame delimiter would make the timecode dropframe
$tc = Time::Timecode->new('00:01:00.02', { dropframe => 0 });
ok(!$tc->is_dropframe);
ok($tc->total_frames, 1802);

# Parse with delimiter char
$tc = Time::Timecode->new('00,22,19;00', { delimiter => ','});
hmsf_ok($tc, 0, 22, 19, 0);

# Parse with frame delimiter char
$tc = Time::Timecode->new('00:00:00+11', { frame_delimiter => '+' });
hmsf_ok($tc, 0, 0, 0, 11);

# Invalid dropframe timecode ';' means dropframe
eval{ $tc = Time::Timecode->new('00:01:00;00') };
ok($@ =~ /invalid dropframe/i);
