#!perl
#
# This example demonstrates controlling the Last.FM stream
# by using WebService::LastFM.
#
# Win32::OLE and iTunes is required to execute this sctipt.
#

use strict;
use WebService::LastFM;
use Getopt::Long;

my %opt;
my $result = GetOptions (
                         "u|username:s" => \$opt{username},
                         "p|password:s" => \$opt{password},
                         "t|tag:s"      => \$opt{tag},
                         "m|player:s"   => \$opt{player},
                         "h|help"       => \$opt{usage},
                        );
my @option_checks = qw/ username password /;
usage() && die "\n" if ( grep( !defined $opt{$_}, @option_checks )  );
usage() && exit if ( $opt{usage} );

# set login data
my $username = $opt{username};
my $password = $opt{password};
my $player   = $opt{player} || '/usr/bin/mpg123 -q';
my $tag      = $opt{tag};

my $lastfm = WebService::LastFM->new(
    username => $username,
    password => $password,
);
my $stream_info;

eval { $stream_info = $lastfm->get_session; };
die "Can't get stream: $@\n" if $@;

if ( defined $tag ) {
  eval { $lastfm->change_tag( $tag ) };
  die "Can't change to $tag: $@\n" if $@;
}

my $playlist = $lastfm->get_new_playlist() or die "Can't get playlist\n";
while ( my $track = $playlist->get_next_track() ) {
  print "Playing '".$track->title."' by ".$track->creator."\n";

  my @cmd = ( split( /\s+/, $player ), $track->location() );
  warn "$!\n" if ( system( @cmd ) );
}

sub usage {
  print <<USAGE;
ctrl.pl -u|--username=username -p|--password password [-t|--tag tagname] [-m|--player player] [-h|--help]

    -u, --username
                 Your LastFM username
    -p, --password
                 Your LastFM password
    -t, --tag
                 The LastFM Tag you want to play
                 If you don't give a tag the last tag you
                 listened to will play
    -m, --player
                 What player you want to use
                 DEFAULT: mpg123 -q
    -h, --help
                 This screen
USAGE

}
