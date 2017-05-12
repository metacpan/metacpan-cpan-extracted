#!/usr/bin/perl

use WWW::TinySong qw(search);

for(search("we are the champions")) {
    printf("%s", $_->{songName});
    printf(" by %s", $_->{artistName});
    printf(" on %s", $_->{albumName}) if $_->{albumName};
    printf(" <%s>\n", $_->{tinysongLink});
}
