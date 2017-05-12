# $Id: Makefile.PL 46 2015-06-30 00:09:18Z stro $

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'          => 'WWW::DreamHost::API',
  'ABSTRACT'      => 'DreamHost Web Panel API',
  'AUTHOR'        => 'Serguei Trouchelle <stro@cpan.org>',
  'VERSION_FROM'  => 'API.pm',
  'LICENSE'       => 'perl',
  'PREREQ_PM'     => {
                         'LWP::UserAgent'       => 0,
                         'Data::UUID'           => 0,
                         'LWP::Protocol::https' => 6.02,
                     },
);
