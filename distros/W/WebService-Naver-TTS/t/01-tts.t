use utf8;
use strict;
use warnings;
use open ':std', ':encoding(utf8)';
use Test::More tests => 1;

use Try::Tiny;
use WebService::Naver::TTS;

my $client_id     = $ENV{WEBSERVICE_NAVER_TTS_ID};
my $client_secret = $ENV{WEBSERVICE_NAVER_TTS_SECRET};

my $client = WebService::Naver::TTS->new( id => $client_id, secret => $client_secret );
my $text = '안녕하세요';

SKIP: {
    skip 'id and secret are required', 1 unless $client;
    my $mp3 = try {
        $client->tts($text);
    }
    catch {
        chomp $_;
        diag("$_\n");
        return;
    };

    ok( $mp3, 'tts' );

    $mp3 = undef;
    $mp3 = try {
        $client->tts( $text, DIR => '.' );
    }
    catch {
        chomp $_;
        diag("$_\n");
        return;
    };

    ok( $mp3, 'tts with tempfile options' );
}
