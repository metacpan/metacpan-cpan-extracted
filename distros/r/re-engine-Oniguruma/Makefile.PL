require 5.009005;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

eval 'use ExtUtils::MakeMaker::Coverage';

my $oe = $Config{obj_ext};
my @obj = map { $_ . $oe } qw(
 Oniguruma onig/* onig/enc/*
);

WriteMakefile(
#  ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
  license( 'perl' ),
  NAME          => 're::engine::Oniguruma',
  AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
  VERSION_FROM  => 'lib/re/engine/Oniguruma.pm',
  ABSTRACT_FROM => 'lib/re/engine/Oniguruma.pm',
  PL_FILES      => {},
  PREREQ_PM     => { 'Test::More' => 0, },
  # OPTIMIZE      => '-g',
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 're-engine-Oniguruma-*' },
  test  => { 'TESTS'  => 't/*.t t/*/*.t' },
  DIR   => ['onig'],
  INC   => '-Ionig',
  OBJECT    => join( ' ', @obj ),
);

sub license {
  my $lic = shift;
  no warnings 'numeric';
  return
   unless $ExtUtils::MakeMaker::VERSION >= '6.31';
  return ( LICENSE => $lic );
}

package MY;

# Need to strip the default subdirs target otherwise BSD make doesn't
# see the real target for some reason.

sub top_targets {
  my $tt = shift->SUPER::top_targets( @_ );
  $tt =~ s{^ subdirs \s .*? ^(\S) }{$1}msgx;
  return $tt;
}

package main;
