#<<<
use strict; use warnings;
#>>>

on 'configure' => sub {
  requires 'App::cpanminus'                => '>= 1.7046';
  requires 'Config'                        => '0';
  requires 'ExtUtils::MakeMaker::CPANfile' => '0';
  requires 'File::Spec'                    => '0';
  requires 'lib'                           => '0';
  requires 'strict'                        => '0';
  requires 'subs'                          => '0';
  requires 'warnings'                      => '0';
};

on 'runtime' => sub {
  requires 'Carp'         => '0';
  requires 'Exporter'     => '0';
  requires 'Scalar::Util' => '0';
  requires 'Try::Tiny'    => '0';
  requires 'overload'     => '0';
  requires 'strict'       => '0';
  requires 'warnings'     => '0';
  recommends 'Time::HiRes' => '>= 1.9726';
};

on 'test' => sub {
  requires 'IO::Handle'  => '0';
  requires 'Test::Fatal' => '0';
  requires 'Test::Needs' => '0';
  requires 'Test::More'  => '0';
};

on 'develop' => sub {
  requires 'Devel::Cover'       => '0';
  requires 'Test::Perl::Critic' => '0';
  requires 'Test::Pod'          => '>= 1.26';
  suggests 'App::CPANtoRPM'         => '0';
  suggests 'App::Software::License' => '0';
};
