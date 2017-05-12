#
# $Id: Makefile.PL 11 2014-04-10 11:55:50Z gomor $
#
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'vFeed',
   LICENSE => 'artistic',
   VERSION_FROM => 'lib/vFeed.pm',
   ABSTRACT_FROM => 'lib/vFeed.pm',
   AUTHOR => 'GomoR <gomor-cpan_at_gomor.org>',
   PREREQ_PM => {
      Class::Gomor => 0,
      LWP::UserAgent => 0,
      Digest::SHA1 => 0,
      Archive::Tar => 0,
      DBI => 0,
   },
   EXE_FILES => [ 'bin/vfeed.pl', ],
   MIN_PERL_VERSION => '5.6.1',
);
