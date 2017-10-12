use Vlc::Engine;
my $player = Vlc::Engine->new();

$player->set_media_list("your fist media from local file or from url");
$player->set_media_list("your second media from local file or from url");

$player->play_list();
sleep(30);
$player->play_next();
sleep(30);
$player->stop_list();
$player->release();

