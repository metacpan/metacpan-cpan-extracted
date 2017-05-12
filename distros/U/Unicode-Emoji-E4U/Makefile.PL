use strict;
require 5.008001;
use ExtUtils::MakeMaker;

my $opt = {
    NAME                =>  'Unicode::Emoji::E4U',
    VERSION_FROM        =>  'lib/Unicode/Emoji/E4U.pm',
    LICENSE             =>  'apache',
    PREREQ_PM           =>  {
        'Test::More'        =>  '0',
        'Test::Harness'     =>  '3.04',
        'Encode'            =>  '0',
        'Any::Moose'        =>  '0',
        'XML::TreePP'       =>  '0.39',
    },
};

WriteMakefile( %$opt );
