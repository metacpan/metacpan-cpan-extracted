#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: Makefile.PL,v 1.5 2007/10/27 12:54:10 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2001 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: srezic@cpan.org
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use ExtUtils::MakeMaker;

WriteMakefile
  (
   'NAME'	  => 'Tk::Enscript',
   'VERSION_FROM' => 'Enscript.pm',
   'PREREQ_PM'     => {'Tk' => 400},

   'dist'	   => {'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},

   'PM'           => {'Enscript.pm'  => '$(INST_LIBDIR)/Enscript.pm',
		      'enscript.cfg' => '$(INST_LIBDIR)/enscript.cfg',
		      ,
		     },
   'clean' => {'FILES' => "tmp/*.ps"},

   'ABSTRACT_FROM' => 'Enscript.pm',
   'AUTHOR'	   => 'Slaven Rezic (srezic@cpan.org)',
);

sub MY::postamble {
    my $postamble = "";

    if (defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk") {
	$postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.cvs.mk"

EOF
    }

    $postamble;
}
