#
# Makefile.PL
#
# Copyright (C) 2001 Gregor N. Purdy.
# All rights reserved.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
#


use ExtUtils::MakeMaker;

WriteMakefile (
  NAME         => 'XPC',
  VERSION_FROM => 'lib/XPC.pm',

  PREREQ_PM => {
    Data::Dumper   => 0,
    HTTP::Daemon   => 0,
    HTTP::Request  => 0,
    HTTP::Status   => 0,
    LWP::UserAgent => 0,
    POSIX          => 0,
    URI            => 0,
    XML::Parser    => 0,
  },

  AUTHOR       => 'Gregor N. Purdy (gregor@focusresearch.com)',
  ABSTRACT     => 'XML Procedure Call',
  EXE_FILES    => [ qw(script/xpcd script/xpcc) ],
  dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' }
);


#
# End of file.
#
