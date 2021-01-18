use strict;
use warnings;

use Exception::Class;
use Test::More tests => 2 + 2;
use Test::NoWarnings;
use WWW::NOS::Open;

my $API_KEY = $ENV{NOSOPEN_API_KEY} || q{TEST};

TODO: {
    todo_skip
q{Need a connection to an NOS Open server. Set the enviroment } .
q{variable NOSOPEN_API_KEY to connect to a server specified in the } .
q{environment variable NOSOPEN_SERVER. A dummy server can be started } .
q{with the command ./scripts/DummyServer.pl},
      2
      unless $ENV{AUTHOR_TESTING} && $ENV{NOSOPEN_SERVER};
    my $obj = WWW::NOS::Open->new($API_KEY);
    my $version = $obj->get_version;
    is( $version->get_version, q{v1},    q{get version number} );
    is( $version->get_build,   q{0.0.1}, q{get build number} );
# For the coverage:
    $obj->get_api_key;
    $obj->set_api_key($API_KEY);
    $obj->get_version;
    $obj->get_latest_articles;
    $obj->get_latest_videos;
    $obj->get_latest_audio_fragments;
    $obj->get_latest_audio_fragments(q{nieuws});
    $obj->search(q{cricket});
    $obj->get_tv_broadcasts;
    $obj->get_radio_broadcasts;
}

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
