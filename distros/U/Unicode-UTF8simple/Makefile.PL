#!/usr/bin/perl
use ExtUtils::MakeMaker;
# vim: set sw=4 ts=4 si et:

WriteMakefile(
    'NAME'                 => 'Unicode::UTF8simple',
    'VERSION_FROM'         => 'UTF8simple.pm', # finds $VERSION,
    'PM'                   => { 
        'UTF8simple.pm' => '$(INST_LIBDIR)/UTF8simple.pm' 
    },
    'MAN3PODS'               => {
        'UTF8simple.pm'    => '$(INST_MAN3DIR)/Unicode::UTF8simple.3',
    },
    dist    => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
