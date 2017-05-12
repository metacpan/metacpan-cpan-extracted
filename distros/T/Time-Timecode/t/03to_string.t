use Test;
use Time::Timecode;
use TestHelper;

BEGIN { plan tests => 17 }

my $tc = Time::Timecode->new('01:02:03:04');
ok($tc->to_string, '01:02:03:04');
ok("$tc", $tc->to_string);

$tc = Time::Timecode->new('00,22,19;00', { delimiter => ',' });
# Should keep original dropframe delimiter...
# Though if the caller is explicitly giving a delimiter it should be horned!
ok($tc->to_string, '00,22,19;00');

# With frame_delimiter char
$tc = Time::Timecode->new('01:02:03:15', { fps => 30, frame_delimiter => '+' });
ok("$tc", '01:02:03+15');

# Check format chars
ok($tc->to_string('%H'), '1');
ok($tc->to_string('%M'), '2');
ok($tc->to_string('%S'), '3');
ok($tc->to_string('%f'), '15');
ok($tc->to_string('%i'), $tc->total_frames);
ok($tc->to_string('%r'), $tc->fps);
ok($tc->to_string('%s'), '50');
ok($tc->to_string('%T'), '01:02:03+15');
ok($tc->to_string('%02H'), '01');
ok($tc->to_string('%02H:%02M:%02S;%02f @ %rfps'), '01:02:03;15 @ 30fps');
ok($tc->to_string(' '), ' ');
ok($tc->to_string('__%X__'), '__%X__');
ok($tc->to_string('%%%HH%%H%'), '%1H%H%');
