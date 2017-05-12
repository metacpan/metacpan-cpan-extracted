###############################################################################
#
# $Id: Makefile.PL 34 2006-10-11 09:07:36Z  $
#
# This is the MakeMaker skeleton for WebService::ISBNDB, a wrapper around
# Module::Build.
#
###############################################################################

use Module::Build::Compat;
Module::Build::Compat->run_build_pl(args => \@ARGV);
Module::Build::Compat->write_makefile();
