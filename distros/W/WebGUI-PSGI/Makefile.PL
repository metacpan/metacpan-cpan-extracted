
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'WebGUI::PSGI',
                       'DISTNAME' => 'WebGUI-PSGI',
                       'AUTHOR' => 'Paul Driver <frodwith@cpan.org>',
                       'ABSTRACT' => 'Run PSGI apps under WebGUI',
                       'EXE_FILES' => [],
                       'VERSION' => '0.2',
                       'LICENSE' => 'perl',
                       'PREREQ_PM' => {
                                        'Apache2::Const' => '0',
                                        'namespace::autoclean' => '0',
                                        'Plack' => '0.9913',
                                        'ExtUtils::MakeMaker' => '6.11',
                                        'Plack::Handler::Apache2' => '0',
                                        'Plack::Middleware' => '0',
                                        'Plack::Response' => '0',
                                        'Plack::App::URLMap' => '0',
                                        'Plack::Request' => '0'
                                      }
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



