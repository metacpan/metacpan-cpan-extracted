#! -*- mode: perl -*-
#
# Author:      Peter John Acklam
# Time-stamp:  2013-03-02 09:42:28 +00:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

use 5.008;              # required version of Perl
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings

use ExtUtils::MakeMaker;

WriteMakefile
  (
   #(MM->can('signature_target') ? (SIGN => 1) : ()),
   NAME             => 'Text::Unaccent::PurePerl',
   AUTHOR           => 'Peter John Acklam <pjacklam@online.no>',
   VERSION_FROM     => 'lib/Text/Unaccent/PurePerl.pm',
   ABSTRACT_FROM    => 'lib/Text/Unaccent/PurePerl.pm',
   PL_FILES         => {},
   PREREQ_PM        => { 'Test::More' => 0, },
   dist             => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
   clean            => { FILES => 'Text-Unaccent-PurePerl-*' },
  );
