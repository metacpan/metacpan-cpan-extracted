# WebService-Naver-TTS #

Perl interface to Naver TTS API

``` perl
my $client = WebService::Naver::TTS->new(id => 'xxxx', secret => 'xxxx');
my $mp3    = $client->tts('안녕하세요');    # $mp3 is Path::Tiny object
```
