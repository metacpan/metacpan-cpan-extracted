use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
  ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
  NAME          => 'XML::RSS::PicLens',
  AUTHOR        => 'Andy Armstrong <andy.armstrong@messagesystems.com>',
  LICENSE       => 'perl',
  VERSION_FROM  => 'lib/XML/RSS/PicLens.pm',
  ABSTRACT_FROM => 'lib/XML/RSS/PicLens.pm',
  PL_FILES      => {},
  PREREQ_PM     => {
    'Test::More'    => 0,
    'Test::XML'     => '0.07',
    'XML::RSS'      => '1.33',
    'Data::Section' => '0.004',
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'XML-RSS-PicLens-*' },
);
