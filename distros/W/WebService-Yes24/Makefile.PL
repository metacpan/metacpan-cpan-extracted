
use strict;
use warnings;

 BEGIN { require 5.010; } 

use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'WebService::Yes24',
                       'DISTNAME' => 'WebService-Yes24',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Keedi Kim - 김도형 <keedi at cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Yes24 Web Service API Module',
                       'EXE_FILES' => [],
                       'VERSION' => '0.100980',
                       'PREREQ_PM' => {
                                        'Test::Base' => '0',
                                        'URI' => '0',
                                        'namespace::autoclean' => '0',
                                        'URI::Escape' => '0',
                                        'Moose::Util::TypeConstraints' => '0',
                                        'Encode' => '0',
                                        'Test::More' => '0',
                                        'Web::Scraper' => '0',
                                        'common::sense' => '0',
                                        'LWP::Simple' => '0',
                                        'Moose' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



