use Vlc::Engine;

my $options = ["--no-video", "--no-xlib"];

my $player = Vlc::Engine->new($playerrray);

sub play
{
    my ($x,$y) = @_;
    print $x, "\n";
}

$player->vlc_version();
$player->set_media("your media from local file or url");

$player->parsing_media();

print $player->get_meta('title') ,"\n";
print $player->get_meta('artist') ,"\n";
print $player->get_meta('genre') ,"\n";

my $manager = $player->event_manager();

$player->event_attach($manager, 'media_player_playing', \&play);
$player->play();
sleep(30);

$player->stop();

$player->stop();
$player->release();

