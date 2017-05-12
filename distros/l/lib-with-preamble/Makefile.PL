use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'lib::with::preamble',
  VERSION_FROM => 'lib/lib/with/preamble.pm',
  PM_FILTER => 'perl my/filter',
  MIN_PERL_VERSION => '5.008001',
  PREREQ_PM => {
    'PerlIO::via::dynamic' => '0.02',
    'File::Spec' => '0',
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    dynamic_config => 0,

    resources => {
      # r/w: p5sagit@git.shadowcat.co.uk:lib-with-preamble.git
      repository => {
        url => 'git://git.shadowcat.co.uk/p5sagit/lib-with-preamble.git',
        web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=p5sagit/lib-with-preamble.git',
        type => 'git',
      },
      bugtracker => {
          mailto => 'bug-lib-with-preamble@rt.cpan.org',
          web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=lib-with-preamble',
      },
    },
  },

);
