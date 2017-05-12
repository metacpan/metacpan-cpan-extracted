use Test;
use Time::Timecode;
use TestHelper;

BEGIN { plan tests => 10 }

my $tc;
{
    local $Time::Timecode::DEFAULT_FPS = 10;
    $tc = Time::Timecode->new(1);
    ok($tc->fps, 10);
    $tc = Time::Timecode->new(1, { fps => 30 });
    ok($tc->fps, 30);
}

{
    local $Time::Timecode::DEFAULT_DROPFRAME = 1;
    $tc = Time::Timecode->new(1);
    ok($tc->is_dropframe, 1);
    $tc = Time::Timecode->new(1, { dropframe => 0 });
    ok($tc->is_dropframe, 0);
}

{
    local $Time::Timecode::DEFAULT_DELIMITER = '.';
    $tc = Time::Timecode->new(1);
    ok("$tc", '00.00.00:01');
    $tc = Time::Timecode->new(1, { delimiter => '-' });
    ok("$tc", '00-00-00:01');
}

{
    local $Time::Timecode::DEFAULT_FRAME_DELIMITER = '.';
    $tc = Time::Timecode->new(1);
    ok("$tc", '00:00:00.01');
    $tc = Time::Timecode->new(1, { frame_delimiter => ',' });
    ok("$tc", '00:00:00,01');
}

{
    local $Time::Timecode::DEFAULT_TO_STRING_FORMAT = '->%02S<-';
    $tc = Time::Timecode->new(2, 1, 0);
    ok("$tc", '->00<-');
    ok($tc->to_string('%02H %02M'), '02 01');
}
