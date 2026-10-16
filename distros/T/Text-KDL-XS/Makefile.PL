use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use Devel::PPPort;

# ckdl reports integers as long long; the XS layer stores them in IVs.
# "OS unsupported" makes CPAN Testers report NA.
die "OS unsupported: Text::KDL::XS needs a perl with 64-bit integers (ivsize >= 8)\n"
    unless $Config{ivsize} >= 8;

# The ckdl sources under ckdl/ are compiled into the extension; see
# ckdl/UPSTREAM.md for the pinned upstream commit and how to update it.
my @ckdl_sources = map { "ckdl/src/$_.c" } qw(bigint compat emitter parser str tokenizer utf8);

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
    # Perls before 5.30 convert number text to floats without correct rounding.
    MIN_PERL_VERSION => '5.030',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '7.06',
        'Devel::PPPort'       => '3.68',
    },
    # ckdl is compiled in, so there is no run-time library dependency.
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
    C      => [ 'XS.c', @ckdl_sources ],
    INC    => '-Ickdl/include',
    DEFINE => ckdl_defines(),
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

# Mirrors what ckdl's CMakeLists.txt sets for a static build. compat.c
# supplies reallocf() unless the C library already has it, which the
# BSD-derived platforms do.
sub ckdl_defines {
    my @defines = qw(-DBUILDING_KDL=1 -DKDL_STATIC_LIB=1);
    push @defines, '-DHAVE_REALLOCF' if $^O =~ /^(?:darwin|freebsd|openbsd|netbsd|dragonfly)$/;
    return join ' ', @defines;
}

# ckdl uses pow() and log10(); link libm explicitly instead of relying on
# the perl binary to provide it.
sub ckdl_libs {
    return $^O eq 'MSWin32' ? '' : '-lm';
}

sub MY::postamble {
    return <<'MAKE_FRAG';

# --- Release target -------------------------------------------------
# Usage: make release
#
# Tests the dist via `make disttest`, builds the tarball via
# `make dist` (disttest alone only creates the unpacked directory),
# then uploads it to CPAN with cpan-upload (from CPAN::Uploader).
# Refuses to run if the git working tree is dirty, if a tag for the
# current $(VERSION) already exists, or if the GitHub CI run of HEAD
# has not passed (ci-check, which needs gh). See RELEASING.md.
#
# disttest and dist run as separate sub-makes on purpose: as
# prerequisites of one target they would share a single distdir
# build, and the tarball would pack the blib/ that disttest left
# behind. PAUSE refuses to index such a tarball.

.PHONY: release release-check ci-check

ci-check :
	@command -v gh >/dev/null 2>&1 || { \
	    echo "ERROR: gh not found in PATH; it reads the CI result of the release commit."; \
	    exit 1; \
	}
	@commit=$$(git rev-parse HEAD) || exit 1; \
	run=$$(gh run list --workflow ci.yml --commit "$$commit" --limit 1 --json status,conclusion --jq '.[] | "\(.status) \(.conclusion)"') || exit 1; \
	case "$$run" in \
	    "completed success") ;; \
	    "") echo "ERROR: no CI run for $$commit; push it and wait for CI first."; exit 1 ;; \
	    "completed "*) echo "ERROR: the CI run for $$commit did not pass ($${run#completed }); see gh run list --commit $$commit."; exit 1 ;; \
	    *) echo "ERROR: the CI run for $$commit has not finished; wait with gh run watch."; exit 1 ;; \
	esac

release-check : ci-check
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

release :: release-check
	$(MAKE) disttest
	$(MAKE) dist
	@test -f $(DISTVNAME).tar.gz || { \
	    echo "ERROR: $(DISTVNAME).tar.gz was not built; refusing to upload."; \
	    exit 1; \
	}
	@if tar tzf $(DISTVNAME).tar.gz | grep -qE '/(blib/|Makefile$$|MYMETA\.|pm_to_blib|XS\.c$$|[^/]*\.(o|so|bs)$$)'; then \
	    echo "ERROR: $(DISTVNAME).tar.gz contains build artefacts; refusing to upload."; \
	    exit 1; \
	fi
	cpan-upload $(DISTVNAME).tar.gz
	@echo
	@echo "Uploaded $(DISTVNAME).tar.gz to PAUSE."
	@echo "Next:"
	@echo "  git tag -a v$(VERSION) -m 'Release v$(VERSION)'"
	@echo "  git push --follow-tags"
MAKE_FRAG
}

{
    package MY;

    # MakeMaker's .c -> .o rule names no output file, so the compiler
    # would write the objects for ckdl/src/*.c next to the Makefile while
    # the link step looks for them in ckdl/src. Name the output explicitly.
    sub c_o {
        my $self = shift;
        my $rules = $self->SUPER::c_o(@_);
        my $object = $self->xs_obj_opt('$*$(OBJ_EXT)');
        $rules =~ s/^(\t\$\(CCCMD\) [^\n]*\$\*\.c)$/$1 $object/m
            or die "Makefile.PL: MakeMaker's .c rule has changed shape; cannot add the object output option\n";
        return $rules;
    }
}
