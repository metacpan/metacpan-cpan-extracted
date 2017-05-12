use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'XML::FeedWriter',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/XML/FeedWriter.pm',
  ABSTRACT_FROM => 'lib/XML/FeedWriter.pm',
  PREREQ_PM => {
    'Class::Accessor::Fast'    => 0,
    'Class::Data::Inheritable' => 0,
    'DateTime'                 => 0,
    'DateTimeX::Web'           => '0.03',
    'Encode'                   => 0,
    'Test::Classy'             => '0.03',
    'Test::More'               => '0.47',
    'Test::UseAllModules'      => '0.09',
    'XML::Writer'              => 0,
  },
  ($ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( LICENSE => 'perl' )
    : ()
  ),
);
