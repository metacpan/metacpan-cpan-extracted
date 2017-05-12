#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: Makefile.PL,v 1.5 2007/10/03 07:51:12 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2001,2009 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use ExtUtils::MakeMaker;

WriteMakefile
  (
   'NAME'	   => 'Tk::CanvasFig',
   'VERSION_FROM'  => 'CanvasFig.pm',
   'PREREQ_PM'     => { Tk => 0 },

   'dist' => {'POSTOP'=>'-$(CHMOD) 644 $(DISTVNAME).tar$(SUFFIX)'},

   'ABSTRACT_FROM' => '',
   'AUTHOR'        => 'Slaven Rezic (slaven@rezic.de)',
    ($ExtUtils::MakeMaker::VERSION >= 6.54 ?
      (META_ADD => { resources => { repository => 'git://github.com/eserte/tk-canvasfig.git' },
		   }) : ()),
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

__END__
