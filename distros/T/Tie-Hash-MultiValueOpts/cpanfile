use strict;
use warnings;

on configure => sub {
  requires 'ExtUtils::MakeMaker'           => '6.76';    # Offers the RECURSIVE_TEST_FILES, NO_PERLLOCAL features
  requires 'ExtUtils::MakeMaker::CPANfile' => '0';       # Needs at least ExtUtils::MakeMaker 6.52
  requires 'File::Spec'                    => '0';
  requires 'strict'                        => '0';
  requires 'warnings'                      => '0'
};

on runtime => sub {
  requires 'Getopt::Std' => '0';
  requires 'Tie::Hash'   => '0';
  requires 'strict'      => '0';
  requires 'warnings'    => '0'
};

on test => sub {
  requires 'Test::More' => '1.001005'    # Subtests accept args
}
