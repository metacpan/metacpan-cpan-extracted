# This code is a part of tux_perl, and is released under the GPL.
# Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
# See README and COPYING for more information, or see
#   http://tux-perl.sourceforge.net/.
#
# $Id: Makefile.PL,v 1.2 2002/11/11 11:15:25 yaleh Exp $

use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tux',
    'DISTNAME'		=> 'tux_perl',
    'VERSION_FROM'	=> 'Tux.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      ( #ABSTRACT_FROM => 'Tux.pm', # retrieve abstract from module
      	ABSTRACT  => 'Perl extension for Tux webserver.',
       AUTHOR     => 'Yale Huang <yale@sdf-eu.org>') : ()),
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
#    'OBJECT'            => '$(O_FILES) xs/libTux$(LIB_EXT)',
    'DIR'               => ['tux'],
    clean  => {'FILES' => 'tux_perl.conf'},
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Tux',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

sub MY::postamble{
'
CONFIG_FILE=tux_perl.conf
INSTALL_CONFIG_FILE=$(PREFIX)/etc/$(CONFIG_FILE)

pure_all :: $(CONFIG_FILE)

$(CONFIG_FILE) ::
'."\t".'sh mksample_conf.sh $(PREFIX) $(INSTALLSITEARCH) >$(CONFIG_FILE)

install :: install_conf

install_conf ::
'."\t".'@echo Install config files...
'."\t".'mkdir -p $(PREFIX)/etc && cp -f $(CONFIG_FILE) $(INSTALL_CONFIG_FILE)

';
}
