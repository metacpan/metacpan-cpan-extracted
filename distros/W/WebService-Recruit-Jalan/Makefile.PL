use strict;
use ExtUtils::MakeMaker;

my $opt = {
    NAME                =>  'WebService::Recruit::Jalan',
    VERSION_FROM        =>  'lib/WebService/Recruit/Jalan.pm',
    PREREQ_PM           =>  {
        'Test::More'        =>  '0',
        'Class::Accessor'   =>  '0',
        'Class::Accessor::Children' =>  '0',
        'XML::OverHTTP'     =>  '0',
    },
};

my $mm = $ExtUtils::MakeMaker::VERSION;
$mm =~ s/[^\d\.]+//g;
$opt->{LICENSE} = 'perl' if ( $mm >= 6.3001 );

WriteMakefile( %$opt );
