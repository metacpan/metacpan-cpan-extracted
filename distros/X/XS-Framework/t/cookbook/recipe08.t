use strict;
use warnings;
BEGIN { require "./t/cookbook/TestCookbook.pm"; }

my $wav = MyTest::Cookbook::WAVFile->new('sample.wav');
my $ogg = MyTest::Cookbook::MultimediaFile->new('sample.ogg', 'ogg');

my $player = MyTest::Cookbook::MultimediaPlayer->new(44100, 6);


subtest "player test" => sub {
    isa_ok($player, 'MyTest::Cookbook::MultimediaPlayer');
    isa_ok($player, 'MyTest::Cookbook::WAVPlayer');
    is $player->quality, 6;
    is $player->preferred_bitrate, 44100;
    is $player->play_file($ogg), 'player is playing sample.ogg (ogg) with quality 6';
    is $player->play_wav($wav), 'wav-player is playing sample.wav with bitrate 44100.000000';
};

subtest "clone test" => sub {
    my $clone = $player->clone;
    isa_ok($clone, 'MyTest::Cookbook::MultimediaPlayer');
    isa_ok($clone, 'MyTest::Cookbook::WAVPlayer');
    is $clone->quality, 6;
    is $clone->preferred_bitrate, 44100;
    is $clone->play_file($ogg), 'player is playing sample.ogg (ogg) with quality 6';
    is $clone->play_wav($wav), 'wav-player is playing sample.wav with bitrate 44100.000000';
};


done_testing;
