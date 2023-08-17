#!perl
use 5.020;
use feature 'signatures';
no warnings 'experimental::signatures';

use WWW::Twitch;
use Getopt::Long;
use Pod::Usage;
use POSIX 'strftime';
use YAML 'LoadFile';

GetOptions(
    'directory|d=s' => \my $stream_dir,
    'dl=s' => \my $youtube_dl,
    'quiet|q' => \my $quiet,
    'max-stale|s=s' => \my $maximum_stale_seconds,
    'channel-id|i=s' => \my $channel_id,
    'config|f=s' => \my $config,
) or pod2usage(2);

$stream_dir //= '.';
$youtube_dl //= 'youtube-dl';
$maximum_stale_seconds //= 15;
$config //= 'twitch-record-live.yml';
if( -f $config ) {
    $config = LoadFile( $config )
} else {
    $config = {}
}

my $twitch = WWW::Twitch->new();
my $channel = $ARGV[0];

sub info( $msg ) {
    if( ! $quiet ) {
        say $msg;
    }
}

sub get_channel_live_info( $channel ) {
    state $info = $twitch->live_stream($channel);
    return $info
}

sub get_channel_id( $channel ) {
    state $id;
    $id //= $channel_id
        //  $config->{channels}->{$channel}
        // do {
            (get_channel_live_info($channel) // {})->{id}
           }
}

sub stream_recordings( $directory, $streamname=$channel ) {
    my $id = get_channel_id( $channel );
    opendir my $dh, $stream_dir
        or die "$stream_dir: $!";

    my @recordings = grep { /\b$id\b.*\.mp4(\.part)?$/ }
                     readdir $dh;
}

if( ! -d $stream_dir ) {
    die "Stream directory '$stream_dir' was not found: $!";
};

# If we have stale recordings, maybe our network went down
# in between
my $stale = $maximum_stale_seconds / (24*60*60);

# Wait for a file to be updated
my @current = grep { -M "$stream_dir/$_" < $stale }
              stream_recordings( $stream_dir, $channel );

# If we have a recent file, we are obviously still recording, no
# need to hit Twitch
if( ! @current ) {
    # Check whether the channel is live
    my $info = get_channel_live_info($channel);
    if( $info ) {
        my $id = $info->{id};
        info( "$channel is live (Stream $id)");
        info( "Launching $youtube_dl in $stream_dir" );
        chdir $stream_dir;
        exec $youtube_dl,
            '-f', 'bestvideo[height<=480]+bestaudio/best[height<=480]',
            '-q', "https://www.twitch.tv/$channel",
            ;
    } else {
        info( "$channel is offline" );
    }
} else {
    info( "$channel is recording (@current)" );
};
