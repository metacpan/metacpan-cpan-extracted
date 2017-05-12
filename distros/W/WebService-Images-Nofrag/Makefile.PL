use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'WebService::Images::Nofrag',
               AUTHOR        => 'franck cuny <franck.cuny@gmail.com>',
               VERSION_FROM  => 'lib/WebService/Images/Nofrag.pm',
               ABSTRACT_FROM => 'lib/WebService/Images/Nofrag.pm',
               PL_FILES      => {},
               PREREQ_PM     => {
                              'Test::More'            => 0,
                              'version'               => 0,
                              'WWW::Mechanize'        => 0,
                              'Class::Accessor::Fast' => 0,
                              'Test::Perl::Critic'    => 0,
                              'Image::Magick'         => 0,
                              'Image::Magick::Info'   => 0,
                              'LWP::Simple'           => 0,
               },
               dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
               clean => { FILES => 'WebService-Images-Nofrag-*' },
);
