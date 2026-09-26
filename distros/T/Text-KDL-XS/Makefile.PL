use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use Alien::ckdl;
use Devel::PPPort;

# ckdl reports integers as long long; the XS layer stores them in IVs.
die "OS unsupported: Text::KDL::XS needs a perl with 64-bit integers (ivsize >= 8)\n"
    unless $Config{ivsize} >= 8;

# Generate ppport.h so XS.xs can compile on a fresh checkout.
# The file is a build artefact and stays out of version control.
Devel::PPPort::WriteFile('ppport.h') unless -e 'ppport.h';

WriteMakefile(
    DISTNAME         => 'Text-KDL-XS',
    NAME             => 'Text::KDL::XS',
    VERSION_FROM     => 'lib/Text/KDL/XS.pm',
    ABSTRACT_FROM    => 'lib/Text/KDL/XS.pm',
    AUTHOR           => 'Davenonymous <perl@davenonymous.com>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.012',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
        'Alien::ckdl'         => '0',
        'Devel::PPPort'       => '3.68',
    },
    BUILD_REQUIRES => {
        'Alien::ckdl' => '0',
    },
    # ckdl is linked statically, so Alien::ckdl is not needed at run time.
    PREREQ_PM => {
        'Carp'           => '0',
        'Exporter'       => '5.57',
        'Math::BigFloat' => '0',
        'Math::BigInt'   => '0',
        'Scalar::Util'   => '0',
        'XSLoader'       => '0',
        'overload'       => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },

    OBJECT => '$(O_FILES)',
    XS     => { 'XS.xs' => 'XS.c' },
    C      => [ 'XS.c' ],
    INC    => Alien::ckdl->cflags_static,
    LIBS   => [ ckdl_libs() ],
    ( $Config{gccversion} ? ( CCFLAGS => "$Config{ccflags} -Wall -Wextra" ) : () ),

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://github.com/Davenonymous/perl-kdl-xs',
            bugtracker => { web => 'https://github.com/Davenonymous/perl-kdl-xs/issues' },
            repository => {
                type => 'git',
                url  => 'https://github.com/Davenonymous/perl-kdl-xs.git',
                web  => 'https://github.com/Davenonymous/perl-kdl-xs',
            },
        },
        dynamic_config => 1,
    },
);

# libkdl.a uses pow() and log10(); link libm explicitly instead of relying on
# the perl binary to provide it.
sub ckdl_libs {
    my $libs = Alien::ckdl->libs_static;
    $libs .= ' -lm' unless $^O eq 'MSWin32';
    return $libs;
}

sub MY::postamble {
    return <<'MAKE_FRAG';

# --- Release target -------------------------------------------------
# Usage: make release
#
# Builds and tests the dist tarball via `make disttest`, then uploads
# it to CPAN with cpan-upload (from CPAN::Uploader). Refuses to run
# if the git working tree is dirty or if a tag for the current
# $(VERSION) already exists. See RELEASING.md.

.PHONY: release release-check

release-check :
	@git diff-index --quiet HEAD -- || { \
	    echo "ERROR: git working tree is dirty; commit or stash first."; \
	    exit 1; \
	}
	@if git rev-parse -q --verify "refs/tags/v$(VERSION)" >/dev/null; then \
	    echo "ERROR: tag v$(VERSION) already exists; bump \$$VERSION in lib/Text/KDL/XS.pm."; \
	    exit 1; \
	fi
	@command -v cpan-upload >/dev/null 2>&1 || { \
	    echo "ERROR: cpan-upload not found in PATH; cpanm CPAN::Uploader"; \
	    exit 1; \
	}
	@test -r $(HOME)/.pause || { \
	    echo "ERROR: ~/.pause not found; see RELEASING.md for the format."; \
	    exit 1; \
	}

release :: release-check disttest
	cpan-upload $(DISTVNAME).tar.gz
	@echo
	@echo "Uploaded $(DISTVNAME).tar.gz to PAUSE."
	@echo "Next:"
	@echo "  git commit -am 'Release v$(VERSION)'"
	@echo "  git tag v$(VERSION)"
	@echo "  git push --follow-tags"
MAKE_FRAG
}
