#!/usr/bin/perl

BEGIN{ require 5.006; }
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'WWW::Scripter::Plugin::JavaScript::SpiderMonkey',
    AUTHOR         => 'Father Chrysostomos <org.cpan@sprout backwards>',
    VERSION_FROM   => 'lib/WWW/Scripter/Plugin/JavaScript/SpiderMonkey.pm',
    ABSTRACT_FROM  => 'lib/WWW/Scripter/Plugin/JavaScript/SpiderMonkey.pm',
    PREREQ_PM      => {
     constant                       => 1.03, # multiple
     constant'lexical               => 0,
     Hash'Util'FieldHash'Compat     => 0,
     HTML'DOM'Interface             => 0,
     JavaScript                     => 1.12, # PerlSub type
     Scalar'Util                    => 0,
     strict                         => 0,
     warnings                       => 0,
     WWW'Scripter'Plugin'JavaScript =>  .005, # back_end
# For testing:
     lib                            => 0,
     Test'More                      => 0,
     URI'file                       => 0,
     WWW'Scripter                   =>  .016, # event2sub and $@
    },
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                TAR => 'COPYFILE_DISABLE=1 tar' },
    clean  => { FILES => 'WWW-Scripter-Plugin-JavaScript-SpiderMonkey-*' },
);
