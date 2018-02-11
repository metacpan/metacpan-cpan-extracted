use Test;
use Time::Timecode;
use TestHelper;

BEGIN { plan tests => 105 }

# Total frames
my $tc = Time::Timecode->new(30);

# Check method aliases
ok($tc->hh, 0);
ok($tc->hrs, 0);
ok($tc->mm, 0);
ok($tc->mins, 0);
ok($tc->ss, 1);
ok($tc->secs, 1);
ok($tc->ff, 0);
ok($tc->total_frames, 30);

$tc = Time::Timecode->new(1, 10, 20);
hmsf_ok($tc, 1, 10, 20, 0);
ok($tc->total_frames, 126600);

$tc = Time::Timecode->new(1, 10, 20, 29);
hmsf_ok($tc, 1, 10, 20, 29);
ok($tc->total_frames, 126629);

$tc = Time::Timecode->new($tc->total_frames);
hmsf_ok($tc, 1, 10, 20, 29);
ok($tc->total_frames, 126629);

# Compare drop/non-drop calculations
$tc = Time::Timecode->new(0, 1, 0, 2, { dropframe => 1 });
hmsf_ok($tc, 0, 1, 0, 2);
ok($tc->total_frames, 1800);

$tc = Time::Timecode->new(0, 1, 0, 2, { dropframe => 0 });
ok($tc->total_frames, 1802);

$tc = Time::Timecode->new(1387252, { dropframe => 0 });
hmsf_ok($tc, 12, 50, 41, 22);

$tc = Time::Timecode->new(1387252, { dropframe => 1 });
hmsf_ok($tc, 12, 51, 28, 0);

$tc = Time::Timecode->new(12, 51, 28, { dropframe => 1 });
ok($tc->total_frames, 1387252);

$tc = Time::Timecode->new(3600, { dropframe => 1, fps => 59.94 });
hmsf_ok($tc, 0, 1, 0, 4);

$tc = Time::Timecode->new(3600, { dropframe => 0, fps => 59.94 });
hmsf_ok($tc, 0, 1, 0, 0);

# Overloads

# Addition
$tc = Time::Timecode->new(29) + Time::Timecode->new(1);
hmsf_ok($tc, 0, 0, 1, 0);
$tc = Time::Timecode->new(29) + 1;
hmsf_ok($tc, 0, 0, 1, 0);
$tc = 1 + Time::Timecode->new(29);
hmsf_ok($tc, 0, 0, 1, 0);

# Results get their settings from the LHS
$tc = Time::Timecode->new(1800, { dropframe => 1 }) + Time::Timecode->new(1);
ok($tc->is_dropframe);
hmsf_ok($tc, 0, 1, 0, 3);
$tc = Time::Timecode->new(24, { fps => 25 }) + Time::Timecode->new(1);
ok($tc->fps, 25);
hmsf_ok($tc, 0, 0, 1, 0);

# Subtraction
$tc = '12:00:00:00' - Time::Timecode->new(1, 0, 0, 1);
hmsf_ok($tc, 10, 59, 59, 29);
$tc =  Time::Timecode->new(1, 0, 10) - 1;
hmsf_ok($tc, 1, 0, 9, 29);
eval { $tc = Time::Timecode->new(1) - 100 };
ok($@ =~ /create timecode/i);

# Not subtraction, this should be moved
eval { $tc = Time::Timecode->new(1, { fps => 'xxx' }) };
ok($@ =~ /fps/);

# Multiplication
$tc =  Time::Timecode->new(0, 1, 0) * Time::Timecode->new(0, 0, 5, 25, { dropframe => 1 });
ok(!$tc->is_dropframe);
hmsf_ok($tc, 2, 55, 0, 0);

# Division
$tc =  31 / Time::Timecode->new(16);
hmsf_ok($tc, 0, 0, 0, 1);

$tc =  Time::Timecode->new(1800) / 3600;
hmsf_ok($tc, 0, 0, 0, 0);

# Comparision
my $tc1 = Time::Timecode->new(0);
my $tc2 = Time::Timecode->new(1800);
ok($tc1 < $tc2);
ok($tc1 <= $tc1);
ok(!($tc2 < $tc1));
ok($tc1 <=> $tc2, -1);
ok($tc1 <=> $tc1, 0);
ok($tc2 <=> $tc1, 1);
ok($tc1 cmp $tc2, -1);
ok($tc1 cmp $tc1, 0);
ok($tc2 cmp $tc1, 1);

# https://rt.cpan.org/Public/Bug/Display.html?id=91181
$tc1 = Time::Timecode->new(23,0,4,29, {dropframe => 1});
$tc2 = Time::Timecode->new(0,0,5,0, {dropframe => 1});
hmsf_ok($tc1 - $tc2, 22, 59, 59, 29);

# Etc...
eval { $tc =  Time::Timecode->new(1) * 200_000_000 };
ok($@ =~ /invalid hours/i);
