# $Id: ExitTask.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Term::ExitTask;

use base qw( Video::DVDRip::Task );

use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

sub configure 	{ 1 }
sub start 	{ shift->ui->glib_main_loop->quit }

1;
