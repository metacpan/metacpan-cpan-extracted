#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Archive::Extract'      => 0.60,
        'CGI::Session'          => 4.42,
        'CTK'                   => 1.16,
        'DBI'                   => 0,
        'Digest'                => 1.16,
        'Digest::MD5'           => 2.36,
        'ExtUtils::Manifest'    => 1.58,
        'File::Copy'            => 2.09,
        'File::Copy::Recursive' => 0.38,
        'File::Find'            => 0,
        'File::Temp'            => 0.22,
        'Module::Load'          => 0,
        'URI'                   => 1.50,
    };
my $exefiles = [qw[
        bin/mlite
    ]];

WriteMakefile(
    'NAME'                  => 'WWW::MLite',
    'DISTNAME'              => 'WWW-MLite',
    'MIN_PERL_VERSION'      => 5.008001,
    'VERSION_FROM'          => 'lib/WWW/MLite.pm', 
    'ABSTRACT_FROM'         => 'lib/WWW/MLite.pm', ,
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'EXE_FILES'             => $exefiles,
    'AUTHOR'                => 'Lepenkov Sergey (Serz Minus) <minus@mail333.com>',
    'LICENSE'               => 'gpl',
    'META_MERGE' => {
        recommends => {
            'DBI'           => 0,
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'http://www.serzik.com',
            repository      => 'http://svn.serzik.com/WWW-MLite/trunk',
            license         => 'http://opensource.org/licenses/gpl-license.php',
        },
    },
);

1;

package MY;

sub postamble {
my $section = <<'MAKE_FRAG';
.PHONY: skel

MYSHAREDIR = share
MYSRCDIR = src
SKELSRC = skel
SKELNAME = $(DISTNAME)-skel
SKELVNAME = $(SKELNAME)-$(VERSION)

skel : $(MYSHAREDIR)$(DFSEP)$(SKELVNAME).tar.gz
	$(NOECHO) $(NOOP)

$(MYSHAREDIR)$(DFSEP)$(SKELVNAME).tar.gz :
	$(PREOP)
	$(TO_UNIX)
	cd $(MYSHAREDIR) && $(TAR) $(TARFLAGS) $(SKELNAME).tar $(SKELSRC)
	$(COMPRESS) $(MYSHAREDIR)$(DFSEP)$(SKELNAME).tar
	$(CP) $(MYSHAREDIR)$(DFSEP)$(SKELNAME).tar.gz $(MYSRCDIR)$(DFSEP)$(SKELVNAME).tar.gz
	-md5sum $(MYSRCDIR)$(DFSEP)$(SKELVNAME).tar.gz > $(MYSRCDIR)$(DFSEP)$(SKELVNAME).md5
	-sha1sum $(MYSRCDIR)$(DFSEP)$(SKELVNAME).tar.gz > $(MYSRCDIR)$(DFSEP)$(SKELVNAME).sha1
	$(POSTOP)

MAKE_FRAG
return $section;
}

1;
