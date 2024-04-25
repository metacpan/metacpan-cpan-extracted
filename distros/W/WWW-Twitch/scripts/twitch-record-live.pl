#!perl
use 5.020;
use experimental 'signatures';

use WWW::Twitch;
use Getopt::Long;
use Pod::Usage;
use POSIX 'strftime';
use YAML 'LoadFile';
use IO::Async;
use Future::AsyncAwait;
use Text::Table;
use Future::Utils 'fmap_scalar';

GetOptions(
    'directory|d=s' => \my $stream_dir,
    'dl=s' => \my $youtube_dl,
    'quiet|q' => \my $quiet,
    'max-stale|s=s' => \my $maximum_stale_seconds,
    'channel-id|i=s' => \my $channel_id,
    'config|f=s' => \my $config,
    'n|dry-run'      => \my $dry_run,
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

sub info( $msg ) {
    if( ! $quiet ) {
        say $msg;
    }
}

my %info;
async sub get_channel_live_info( $channel ) {
    my $res;
    if( exists $info{ $channel }) {
        $res = $info{ $channel }
    } else {
        $res = $info{ $channel } = await $twitch->live_stream_f($channel);
    };
    return $res
};

async sub get_channel_id( $channel ) {
    my $id //= $channel_id
        // $config->{channels}->{$channel}
        // do {
            my $i = await get_channel_live_info($channel);
            ($i // {})->{id}
           };
    return $id
};

async sub stream_recordings( $directory, $streamname ) {
    my $id = await get_channel_id( $streamname );
    opendir my $dh, $stream_dir
        or die "$stream_dir: $!";
    my @recordings;
    if( $id ) {
        @recordings = grep { /\b$id\b.*\.mp4(\.part)?\z/ }
                     readdir $dh;
    };
    return @recordings
};

if( ! -d $stream_dir ) {
    die "Stream directory '$stream_dir' was not found: $!";
};

# If we have stale recordings, maybe our network went down
# in between
my $stale = $maximum_stale_seconds / (24*60*60);

async sub currently_recording( $channel ) {
    my @current = grep { -M "$stream_dir/$_" < $stale }
                  await stream_recordings( $stream_dir, $channel );
};

async sub check_channel( $channel ) {
    # Check whether the channel is live
    my $info = await get_channel_live_info($channel);
    if( $info ) {
        my $id = $info->{id};
        return { channel => $channel, id => $id, status => 'live' };
    } else {
        return { channel => $channel, id => undef, status => undef };
    }
};

async sub fetch_info( $channel ) {
    await currently_recording( $channel )->then(async sub(@r) {
        my $res;
        #say sprintf "%s has %d files", $channel, scalar @r;
        my $res;
        if( @r ) {
            # If we have a recent file, we are obviously still recording, no
            # need to hit Twitch
            $res = +{ channel => $channel, status => 'recording' };
        } else {
            my $s = await check_channel( $channel );
            if( $s ) {
                $res = $s;
            } else {
                $res = +{ channel => $channel, status => undef };
            }
        }
        return $res
    });
}

sub check_channels( @channels ) {
    my @fetch = map {
        my $res = fetch_info("$_");
        $res
    } @channels;
    my @status = Future->wait_all(@fetch)->catch(sub { use Data::Dumper; warn Dumper \@_ })->get;
    return map { $_->get } @status
};

my @channels = check_channels( @ARGV );
my $t = Text::Table->new("Channel", "Status");
$t->load( map { [ $_->{channel}, $_->{status} // 'offline' ]} @channels );
info( $t );

for my $channel (@channels) {
    if( $channel->{status} eq 'live' ) {
        info( "Launching $youtube_dl in $stream_dir" );
        if( ! $dry_run ) {
            chdir $stream_dir;
            # Ugh, we can't do exec() if we have multiple streams ...
            if( my $pid = fork ) {
                info("Download started as pid $pid");
            } else {
                exec $youtube_dl,
                    '-f', 'bestvideo[height<=480]+bestaudio/best[height<=480]/bestvideo[height<=720]/bestvideo',
                    '-q', "https://www.twitch.tv/$channel->{channel}",
                    ;
                die "Couldn't launch $youtube_dl: $!";
            };
        };
    }
}
