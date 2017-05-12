
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Vim::Complete',
                       'DISTNAME' => 'Vim-Complete',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Generate auto completion information for vim',
                       'EXE_FILES' => [
                                        'bin/mk_vim_complete'
                                      ],
                       'VERSION' => '1.100880',
                       'PREREQ_PM' => {
                                        'Class::Accessor::Complex' => '0',
                                        'PPI' => '0',
                                        'Scalar::Util' => '0',
                                        'parent' => '0',
                                        'English' => '0',
                                        'Pod::Usage' => '0',
                                        'FindBin' => '0',
                                        'File::Spec' => '0',
                                        'Carp' => '0',
                                        'Test::More' => '0.88',
                                        'Test::Differences' => '0',
                                        'File::Find' => '0',
                                        'File::Temp' => '0',
                                        'Getopt::Attribute' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



