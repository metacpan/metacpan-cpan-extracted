use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'WWW::3Taps::API',
  AUTHOR        => q{Eden Cardim <edencardim@gmail.com>},
  VERSION_FROM  => 'lib/WWW/3Taps/API.pm',
  ABSTRACT_FROM => 'lib/WWW/3Taps/API.pm',
  ( $ExtUtils::MakeMaker::VERSION >= 6.3002
    ? ( 'LICENSE' => 'perl' )
    : () ),
  PL_FILES  => {},
  PREREQ_PM => {
    'Test::More'                      => 0,
    'Test::Exception'                 => 0,
    'Moose'                           => 0,
    'MooseX::Types'                   => 0,
    'MooseX::Params::Validate'        => 0,
    'MooseX::Types::Structured'       => 0,
    'MooseX::Types::Moose'            => 0,
    'MooseX::Types::Locale::Language' => 0,
    'LWP::UserAgent'                  => 0,
    'JSON::Any'                       => 0,
    'URI'                             => 0,
    'DateTimeX::Easy'                 => 0
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'WWW-3Taps-API-*' },
);
