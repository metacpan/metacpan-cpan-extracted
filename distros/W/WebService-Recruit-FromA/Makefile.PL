use strict;
use ExtUtils::MakeMaker;

my $opt = {
    NAME                =>  'WebService::Recruit::FromA',
    VERSION_FROM        =>  'lib/WebService/Recruit/FromA.pm',
    PREREQ_PM           =>  {
        'Test::More'        =>  '0',
        'Class::Accessor'   =>  '0',
        'Class::Accessor::Children'   =>  '0',
        'XML::OverHTTP'     =>  '0',
    },
    AUTHOR              => 'RECRUIT Media Technology Labs <mtl@cpan.org>',
};

$opt->{ABSTRACT} =<<END_OF_ABSTRACT_TEXT;
お仕事検索webサービスは、フロム・エー ナビ上に登録されているお仕事情報を取得できるAPI です。
リクエストURL にパラメータを付けたHTTP リクエストに対し、XML 形式でレスポンスを返します（REST 方式）。リクエストパラメータとしては、職種、勤務期間、勤務日数、勤務時間帯、検索パターン、取得件数、データ取得エリア（市区町村レベル）など様々なパラメータを備えています。
また、戻り値として返されるXMLには、お仕事に関する基本的な情報だけでなく、勤務地の郵便番号や勤務地の緯度・経度情報、写真画像のURLなども含まれており、様々な情報サービスへの展開が期待できる仕様となっています。
END_OF_ABSTRACT_TEXT

my $mm = $ExtUtils::MakeMaker::VERSION;
$mm =~ s/[^\d\.]+//g;
$opt->{LICENSE} = 'BSD' if ( $mm >= 6.3001 );

WriteMakefile( %$opt );
