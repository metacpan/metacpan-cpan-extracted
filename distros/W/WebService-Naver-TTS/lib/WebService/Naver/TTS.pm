package WebService::Naver::TTS;
$WebService::Naver::TTS::VERSION = 'v0.0.1';
use utf8;
use strict;
use warnings;

use HTTP::Tiny;
use Path::Tiny;

=encoding utf8

=head1 NAME

WebService::Naver::TTS - Perl interface to Naver TTS API

=head1 SYNOPSIS

    my $client = WebService::Naver::TTS->new(id => 'xxxx', secret => 'xxxx');
    my $mp3    = $client->tts('안녕하세요');    # $mp3 is Path::Tiny object

=head1 METHODS

=head2 new( id => $id, secret => $secret, \%options )

L<API 권한 설정 및 호출 방법|https://developers.naver.com/docs/common/apicall/>

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
                agent                   => 'WebService::Naver::TTS - Perl interface to Naver TTS API',
                'X-Naver-Client-Id'     => $args{id},
                'X-Naver-Client-Secret' => $args{secret},
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

=back

=cut

sub speaker {
    my ( $self, $speaker ) = @_;
    return unless $speaker;

    $self->{speaker} = $speaker;
}

=head2 tts($text)

    my $mp3 = $client->tts('안녕하세요');

C<$mp3> is L<Path::Tiny/"tempfile, tempdir"> obj.

C<$mp3> is C<undef> if failed.

=cut

our $URL = "https://openapi.naver.com/v1/voice/tts.bin";

sub tts {
    my ( $self, $text ) = @_;
    return unless $text;

    my $res = $self->{http}->post_form( $URL, { speaker => $self->{speaker}, speed => $self->{speed}, text => $text } );

    die "Failed to convert text($text) to speech file: $res->{reason}\n" unless $res->{success};

    my $temp = Path::Tiny->tempfile;
    $temp->spew_raw( $res->{content} );
    return $temp;
}

__END__

=head1 COPYRIGHT and LICENSE

The MIT License (MIT)

Copyright (c) 2017 Hyungsuk Hong

=cut


1;
