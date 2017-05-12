use strict;
use warnings;
use Test::More;
use WebService::Shutterstock::Video;
use Test::MockModule;
use WebService::Shutterstock::Client;

my $video = WebService::Shutterstock::Video->new(
	client   => WebService::Shutterstock::Client->new,
	video_id => 1,
	sizes => { "sd_mpeg" => { width => 640, height => 480, aspect => 1.333 } },
	is_available => 1,
);
isa_ok($video, 'WebService::Shutterstock::Video');

ok $video->size('sd_mpeg'), 'has sd_mpeg size';
ok !$video->size('blah'), 'no blah size';

ok $video->is_available, 'is available';

done_testing;
