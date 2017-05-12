#
# Copyright (C) 2014-2016 by Tomasz Konojacki
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.18.2 or,
# at your option, any later version of Perl 5 you may have available.
#

use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # developer release/version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    NAME              => 'Tie::ConfigFile',
    VERSION_FROM      => 'lib/Tie/ConfigFile.pm',
    PREREQ_PM         => {
        IO::File   => 0,
        File::Temp => 0,
        File::AtomicWrite => 0,
    },
    ABSTRACT_FROM  => 'lib/Tie/ConfigFile.pm',
    AUTHOR         => 'Tomasz Konojacki <me@xenu.tk>',
    META_MERGE    => {
         resources => {
             repository => 'http://code.xenu.pl/repos.cgi/tie-configfile'
         }
    },
    # tests fail on older versions
    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => '5.012001')
        : ()
    ),
);
