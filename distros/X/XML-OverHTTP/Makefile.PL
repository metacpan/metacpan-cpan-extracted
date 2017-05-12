use strict;
use ExtUtils::MakeMaker;

my $opt = {
    NAME                =>  'XML::OverHTTP',
    VERSION_FROM        =>  'lib/XML/OverHTTP.pm',
    PREREQ_PM           =>  {
        'Test::More'        =>  '0',
        'CGI'               =>  '0',
        'Class::Accessor::Fast'          => '0',
        'Class::Accessor::Chained::Fast' => '0',
        'Data::Page'        =>  '0',
        'Data::Pageset'     =>  '0',
#       'LWP::UserAgent'    =>  '0',
#       'HTTP::Lite'        =>  '0',
        'XML::TreePP'       =>  '0.33',
    },
};

my $mm = $ExtUtils::MakeMaker::VERSION;
$mm =~ s/[^\d\.]+//g;
$opt->{LICENSE} = 'perl' if ( $mm >= 6.3001 );

WriteMakefile( %$opt );
