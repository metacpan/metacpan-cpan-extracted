package WebService::Naver::TTS;
$WebService::Naver::TTS::VERSION = 'v0.0.3';
use utf8;
use strict;
use warnings;

use HTTP::Tiny;
use Path::Tiny;

=encoding utf8

=head1 NAME

WebService::Naver::TTS - Perl interface to Naver TTS API

Clova Speech Synthesis(CSS)

=head1 SYNOPSIS

    my $client = WebService::Naver::TTS->new(id => 'xxxx', secret => 'xxxx');
    my $mp3    = $client->tts('안녕하세요');    # $mp3 is Path::Tiny object

=head1 METHODS

=head2 new( id => $id, secret => $secret, \%options )

L<CSS API 란?|http://docs.ncloud.com/ko/naveropenapi_v2/naveropenapi-4-2.html>

    my $client = WebService::Naver::TTS->new(id => $client_id, secret => $client_secret);

=head3 \%options

=over

=item C<speaker>

See L</"speaker($speaker)">

=item C<speed>

Interger value between C<-5> and C<5>.
C<0> is default.

-5 ~ 5 사이 정수로 -5면 0.5배 빠른, 5면 0.5배 느린, 0이면 정상 속도의 목소리로 합성

=back

=cut

sub new {
    my ( $class, %args ) = @_;
    return unless $args{id};
    return unless $args{secret};

    my $self = {
        key     => $args{id},
        secret  => $args{secret},
        speaker => $args{speaker} || 'mijin',
        speed   => $args{speed} // 0,
        http    => HTTP::Tiny->new(
            default_headers => {
                agent                    => 'WebService::Naver::TTS - Perl interface to Naver Clova Speech Synthesis API',
                'X-NCP-APIGW-API-KEY-ID' => $args{id},
                'X-NCP-APIGW-API-KEY'    => $args{secret},
            }
        ),
    };

    bless $self, $class;
    return $self;
}

=head2 speaker($speaker)

=over

=item *

B<mijin> 미진(한국어, 여성) - default

=item *

B<jinho> 진호(한국어, 남성)

=item *

B<clara> 클라라(영어, 여성)

=item *

B<matt> 매튜(영어, 남성)

=item *

B<yuri> 유리(일본어, 여성)

=item *

B<shinji> 신지(일본어, 남성)

=item *

B<meimei> 메이메이(중국어, 여성)

=item *

B<liangliang> 중국어, 남성

=item *

B<jose> 스페인어, 남성

=item *

B<carmen> 스페인어, 여성

=back

=cut

sub speaker {
    my ( $self, $speaker ) = @_;
    return unless $speaker;

    $self->{speaker} = $speaker;
}

=head2 tts($text, %tmp_opts?)

    my $mp3 = $client->tts('안녕하세요');

C<$text> 음성 합성할 문장. UTF-8 인코딩된 텍스트만 지원합니다. CSS API 는 최대 5000 자의 텍스트까지 음성 합성을 지원합니다.

C<$mp3> is L<Path::Tiny/"tempfile, tempdir"> obj.

C<$mp3> is C<undef> if failed.

C<%tmp_opts> is L<File::Temp> options.

=over

=item *

  DIR => $dir

=item *

  SUFFIX => '.dir'

=item *

  TMPDIR => 1

default is C<1>

=back

=cut

our $URL = "https://naveropenapi.apigw.ntruss.com/voice/v1/tts";

sub tts {
    my ( $self, $text, %tmp_opts ) = @_;
    return unless $text;

    my $res = $self->{http}->post_form( $URL, { speaker => $self->{speaker}, speed => $self->{speed}, text => $text } );

    die "Failed to convert text($text) to speech file: $res->{reason}\n\n$res->{content}\n" unless $res->{success};

    my $temp = Path::Tiny->tempfile(%tmp_opts);
    $temp->spew_raw( $res->{content} );
    return $temp;
}

__END__

=head1 COPYRIGHT and LICENSE

The MIT License (MIT)

Copyright (c) 2018 Hyungsuk Hong

=cut

1;
