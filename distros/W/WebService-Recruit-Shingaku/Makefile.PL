use strict;
use ExtUtils::MakeMaker;

my $opt = {
    NAME                =>  'WebService::Recruit::Shingaku',
    VERSION_FROM        =>  'lib/WebService/Recruit/Shingaku.pm',
    PREREQ_PM           =>  {
        'Test::More'        =>  '0',
        'Class::Accessor'   =>  '0',
        'Class::Accessor::Children'   =>  '0',
        'XML::OverHTTP'     =>  '0',
    },
    AUTHOR              => 'RECRUIT Media Technology Labs <mtl@cpan.org>',
};

$opt->{ABSTRACT} =<<END_OF_ABSTRACT_TEXT;
リクルート進学ネットに掲載されている学校および各種学問・仕事・資格を様々な軸で検索できるAPIです。
END_OF_ABSTRACT_TEXT

my $mm = $ExtUtils::MakeMaker::VERSION;
$mm =~ s/[^\d\.]+//g;
$opt->{LICENSE} = 'BSD' if ( $mm >= 6.3001 );

WriteMakefile( %$opt );
