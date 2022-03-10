#!perl
use 5.020;
use feature 'signatures';

use WWW::Twitch;
use Data::Dumper;
use Text::Table;

my $twitch = WWW::Twitch->new();

my @out;

#my $channel = 'twitchfarming';
my $channel = 'bootiemashup';
my $info = $twitch->live_stream($channel);

if( $info ) {
    my $id = $info->{id};
    say "$channel is live (Stream $id)";
} else {
    say "$channel is offline";
}

my $s = $twitch->schedule('papalatte');
if( ! $s ) {
    say "No schedule for that?";
};

for my $entry ( @{ $s->{segments} } ) {
    push @out, [ $entry->{title}, $entry->{startAt} ];
    #use Data::Dumper;
    #say Dumper $entry;
};

my $t = Text::Table->new('Title','Start');
$t->load( @out );
say $t;


say Dumper $twitch->is_live('papalatte');
say Dumper $twitch->is_live('PDSMix');

# Get live stream id
# check if file exists (and is recent enough?!)
# if not, launch detached youtube-dl to download
