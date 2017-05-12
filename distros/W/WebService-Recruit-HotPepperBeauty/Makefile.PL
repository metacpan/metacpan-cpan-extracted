use strict;
use ExtUtils::MakeMaker;

my $opt = {
    NAME                =>  'WebService::Recruit::HotPepperBeauty',
    VERSION_FROM        =>  'lib/WebService/Recruit/HotPepperBeauty.pm',
    PREREQ_PM           =>  {
        'Test::More'        =>  '0',
        'Class::Accessor'   =>  '0',
        'Class::Accessor::Children'   =>  '0',
        'XML::OverHTTP'     =>  '0',
    },
    AUTHOR              => 'RECRUIT Media Technology Labs <mtl@cpan.org>',
};

$opt->{ABSTRACT} =<<END_OF_ABSTRACT_TEXT;
ホットペッパーBeauty Webサービスを使うことで、ホットペッパーBeautyに掲載されている、サロン情報にアクセスして、アプリケーションを構築することができます。
END_OF_ABSTRACT_TEXT

my $mm = $ExtUtils::MakeMaker::VERSION;
$mm =~ s/[^\d\.]+//g;
$opt->{LICENSE} = 'BSD' if ( $mm >= 6.3001 );

WriteMakefile( %$opt );
