#!perl

use strict;
use warnings;

use Test::More;
use LWP::UserAgent ();
use WWW::Mechanize ();
use WWW::Spotify   ();

{
    my $ua = WWW::Mechanize->new( autocheck => 0 );
    $ua->agent('foo');
    is(
        WWW::Spotify->new( ua => $ua )->ua->agent,
        'foo',
        'uses custom WWW::Mechanize ua'
    );
}

{
    my $ua = LWP::UserAgent->new;
    $ua->agent('foo');
    is(
        WWW::Spotify->new( ua => $ua )->ua->agent,
        'foo',
        'uses custom LWP::UserAgent ua'
    );
}

done_testing();
