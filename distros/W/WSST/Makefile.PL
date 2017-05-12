use strict;
use ExtUtils::MakeMaker;

my $opt = {
    NAME                =>  'WSST',
    VERSION_FROM        =>  'lib/WSST.pm',
    PREREQ_PM           =>  {
        'Test::More'        =>  '0',
        'Getopt::Long'      =>  '0',
        'Pod::Usage'        =>  '0',
        'File::Find'        =>  '0',
        'File::Basename'    =>  '0',
        'File::Path'        =>  '0',
        'Storable'          =>  '0',
        'YAML'              =>  '0',
        'Template'          =>  '0',
        'Class::Accessor'   =>  '0',
    },
    EXE_FILES           => [
        'bin/wsst',
    ],
    ABSTRACT            => 'WSST is a tool to generate libraries which manipulate web service.',
    AUTHOR              => 'Mitsuhisa Oshikawa <mitsuhisa@gmail.com>, Yusuke Kawasaki <u-suke@kawa.net>',
};

my $mm = $ExtUtils::MakeMaker::VERSION;
$mm =~ s/[^\d\.]+//g;
$opt->{LICENSE} = 'BSD' if ( $mm >= 6.3001 );

WriteMakefile( %$opt );
