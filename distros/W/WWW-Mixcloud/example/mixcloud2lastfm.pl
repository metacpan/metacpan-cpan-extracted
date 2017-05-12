# Example script showing use of WWW::Mixcloud by parsing a cloudcast
# URL and submitting all the tracks in the sections of the cloudcast
# to last.fm for scrobbling.

#!/usr/env/perl

use strict;
use warnings;

use WWW::Mixcloud;
use Net::LastFM::Submission;

my $url = $ARGV[0] or die "Mixcloud URL required";

my $submit = Net::LastFM::Submission->new(
    user      => 'user',
    password  => 'password',
);

$submit->handshake;

my $mixcloud = WWW::Mixcloud->new;
my $cloudcast = $mixcloud->get_cloudcast( $url );

my $time = time;
my $count = 0;
foreach my $section ( @{$cloudcast->sections} ) {

    my $artist = $section->track->artist->name;
    my $title = $section->track->name;

    print "Scrobbling: $artist - $title \n";

    $submit->submit(
        artist => $artist,
        title  => $title,
        time   => $time - ( $count * 3 * 60 ),
    );

    $count++;
}
