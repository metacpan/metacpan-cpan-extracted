# Makefile.PL -- Makefile template for Pod::Lyx
#
# This file is part of "Pod::Lyx". Pod::Lyx and pod2lyx are freee software;
# you can redistribute it and/or modify it under the same terms as
# perl itself.

BEGIN {
    require 5.005;
    eval { require File::Spec };
    $@ and die "You need to install the File::Spec module first!\n";
}

use ExtUtils::MakeMaker;

$DISTNAME   =   "pod2lyx";      # the "Product" name for this distribution
$DISTMOD    =   'Pod::Lyx';     # the "title" module of this distribution
@MODULES    = ( $DISTMOD );

@SCRIPTS    = qw( pod2lyx );    # scripts to be installed.

sub script($) { File::Spec->catfile ('scripts', @_) }
my @EXE_FILES = map { script $_ } @SCRIPTS;


#===============================================================================
# Instructions to write the Makefile ( see ExtUtils::MakeMaker )

WriteMakefile(
    NAME                => $DISTMOD,
    DISTNAME            => $DISTNAME,
    VERSION_FROM        => 'lib/Pod/Lyx.pm', # finds $VERSION
    EXE_FILES           => [ @EXE_FILES ],
    dist                => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    ($] < 5.005 ?       ### Need File::Spec if this is 5.004 or earlier
        (PREREQ_PM  => { 'File::Spec' => 0}) : ()),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (ABSTRACT   => 'Convert pod data to a format readable by LyX ',
        AUTHOR     => 'Richard D. Jackson <richardj@1gig.net>') : ()),
);
