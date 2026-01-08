use strict;
use warnings;

on configure => sub {
  requires 'ExtUtils::MakeMaker'           => '6.76';    # Offers the RECURSIVE_TEST_FILES, NO_PERLLOCAL features
  requires 'ExtUtils::MakeMaker::CPANfile' => '0';       # Needs at least ExtUtils::MakeMaker 6.52
  requires 'File::Spec::Functions'         => '0';
  requires 'strict'                        => '0';
  requires 'warnings'                      => '0';
};

on runtime => sub {
  requires 'Carp'     => '1.32';                         # Don't vivify @CARP_NOT and @ISA in caller's namespace
  requires 'overload' => '0';
  requires 'strict'   => '0';
  requires 'warnings' => '0';
};

on test => sub {
  requires 'Test::API'   => '0';
  requires 'Test::Fatal' => '== 0.017';
  requires 'Test::More' => '1.001005'                    # Subtests accept args
}
