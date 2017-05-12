use ExtUtils::MakeMaker;
# $Id: Makefile.PL,v 1.1 2001/12/13 21:46:15 jgsmith Exp $

WriteMakefile( NAME => 'Text::Domain',
               VERSION_FROM => 'lib/Text/Domain.pm',
               PREREQ_PM =>    { Locale::gettext => 1.01,
                               },
               dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
             );
