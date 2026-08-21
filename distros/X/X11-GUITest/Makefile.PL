# X11::GUITest ($Id: Makefile.PL 249 2026-08-15 18:43:40Z ctrondlp $)

use strict;
use Config;
use File::Copy qw(copy);
use File::Spec;
use ExtUtils::MakeMaker;

# File::Temp became core in Perl 5.6.1; this module otherwise tries to work
# with much older Perls (see the 5.005/5.008 guards below), so probing is
# simply skipped -- falling back to the old directory-existence guesses --
# on anything old enough not to have it.
my $HAVE_FILE_TEMP = eval { require File::Temp; File::Temp->import('tempdir'); 1 };

# --- CLI Handler for "make docs" Callback ---
if (@ARGV && $ARGV[0] eq '--build-docs') {
    BuildDocs();
    exit 0;
}

# --- EUMM Version Compatibility Guards ---
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//g;

my %extra_params;

if ($eumm_version >= 6.31) {
    $extra_params{LICENSE} = 'gpl_2';
}

if ($eumm_version >= 6.46) {
    $extra_params{META_ADD} = {
        resources => {
            homepage   => 'https://sourceforge.net/projects/x11guitest/',
            bugtracker => {
                web => 'https://sourceforge.net/p/x11guitest/tickets/',
            },
        },
    };
    $extra_params{META_MERGE} = {
        resources => {
            repository => {
                type => 'svn',
                url  => 'https://svn.code.sf.net/p/x11guitest/code/trunk',
                web  => 'https://sourceforge.net/p/x11guitest/code/HEAD/tree/trunk/',
            },
        },
    };
}

# --- Compiler Flag Portability Guard ---
# Only append -Wall if using GCC/Clang to avoid breaking native compilers on HP-UX/Solaris/AIX
my $ccflags = $Config{ccflags} || '';
if ($Config{gccversion}) {
    $ccflags .= ' -Wall';
}

# --- Locate X11/XTest headers & libraries ---
# Rather than trusting a fixed list of "does this directory exist" guesses,
# determine what actually works: prefer pkg-config when it knows about x11/
# xtst, otherwise probe candidate locations with a real compile+link and
# keep the first one that succeeds. Only if neither approach can confirm a
# working combination (e.g. no usable compiler available at configure time,
# or File::Temp is unavailable on a very old Perl) do we fall back to the
# previous directory-existence heuristic.
my ($X11_LIBS, $X11_INC) = DetermineX11Flags();

WriteMakefile(
    'NAME'          => 'X11::GUITest',
    ($] ge '5.005') ? (
        'AUTHOR'    => 'Dennis K. Paulsen <ctrondlp@cpan.org>',
    ) : (),
    'VERSION_FROM'  => 'GUITest.pm',
    'ABSTRACT_FROM' => 'GUITest.pm',
    ($] lt '5.008') ? (
        'INST_MAN3DIR' => './blib/man3',
        'MAN3EXT'      => '3pm'
    ) : (),
    'MAN3PODS'      => {'GUITest.pm' => '$(INST_MAN3DIR)/X11::GUITest.$(MAN3EXT)'},
    'LIBS'          => $X11_LIBS,
    # If the target X server has Xinerama active, XTestFakeMotionEvent() is
    # known to misbehave for MoveMouseAbs(). An alternate XWarpPointer()-based
    # implementation exists but isn't auto-detected -- see the DEPENDENCIES
    # section in GUITest.pm for how to opt in via X11_GUITEST_USING_XINERAMA.
    'DEFINE'        => '-DNDEBUG -DX11_GUITEST_ALT_L_FALLBACK_META_L',
    'INC'           => $X11_INC,
    'CCFLAGS'       => $ccflags,
    'OBJECT'        => 'GUITest$(OBJ_EXT) KeyUtil$(OBJ_EXT)',
    'OPTIMIZE'      => '-O2',
    %extra_params,
);


# --- Candidate (include, lib) install-tree pairs to probe, in preference order ---
# Each pair represents one plausible self-contained X11 installation prefix.
# These are only ever used if pkg-config can't tell us, and even then only
# the first pair that actually compiles & links a real X11/XTest test
# program is kept -- see DetermineX11Flags()/CanBuildX11Test() below.
my @X11_PROFILES = (
    # Linux
    ['/usr/X11R6/include',         '/usr/X11R6/lib64'],
    ['/usr/X11R6/include',         '/usr/X11R6/lib'],
    ['/usr/include',               '/usr/lib64'],
    ['/usr/include',               '/usr/lib'],
    # FreeBSD / OpenBSD (ports/pkg install under /usr/local)
    ['/usr/local/include/X11',     '/usr/local/lib'],
    ['/usr/local/include',         '/usr/local/lib'],
    # NetBSD pkgsrc
    ['/usr/pkg/include',           '/usr/pkg/lib'],
    # Solaris: legacy OpenWindows tree (32-bit and 64-bit), modern /usr/X11
    # alias, and the two third-party package managers admins commonly rely
    # on when the base OS has no X11 dev files or toolchain at all.
    ['/usr/openwin/include',       '/usr/openwin/lib'],
    ['/usr/openwin/include',       '/usr/openwin/lib/64'],
    ['/usr/X11/include',           '/usr/X11/lib'],
    ['/opt/csw/include',           '/opt/csw/lib'],
    ['/usr/sfw/include',           '/usr/sfw/lib'],
    # HP-UX: HP shipped both a "base" and a separate "contrib" X11R6 tree
    ['/usr/include/X11R6',         '/usr/lib/X11R6'],
    ['/usr/contrib/X11R6/include', '/usr/contrib/X11R6/lib'],
    ['/opt/X11R6/include',         '/opt/X11R6/lib'],
    # AIX: base X11 fileset, and the AIX Toolbox for Linux Applications
    # (the common source of open-source dependencies on AIX)
    ['/usr/lpp/X11/include',       '/usr/lpp/X11/lib'],
    ['/usr/lpp/X11/include',       '/usr/lpp/X11/lib64'],
    ['/opt/freeware/include',      '/opt/freeware/lib'],
    # Misc legacy alias seen on some Unixes
    ['/usr/X/include',             undef],
);

# --- Determines the LIBS/INC WriteMakefile args for X11 + XTest ---
sub DetermineX11Flags {
    if (my ($libs, $inc) = TryPkgConfig()) {
        print "Using pkg-config for X11/XTest build flags.\n";
        return ($libs, $inc);
    }

    if ($HAVE_FILE_TEMP) {
        if (CanBuildX11Test()) {
            print "X11/XTest found via the compiler's default search paths.\n";
            return ('-lXtst -lX11', '');
        }
        for my $profile (@X11_PROFILES) {
            my ($inc, $lib) = @$profile;
            next if $inc && !-d $inc;
            next if $lib && !-d $lib;
            if (CanBuildX11Test($inc, $lib)) {
                print "X11/XTest found under: ", join(', ', grep { defined } $inc, $lib), "\n";
                my @libflags;
                push @libflags, "-L$lib" if $lib;
                push @libflags, '-lXtst', '-lX11';
                return (join(' ', @libflags), $inc ? "-I$inc" : '');
            }
        }
        print "Warning: Could not verify a working X11/XTest combination by ",
              "compiling a test program. Falling back to directory-existence ",
              "guesses; the build may still fail.\n";
    }

    # Last resort: nothing above could confirm a working combination (no
    # File::Temp, or no compiler available yet), so fall back to the old
    # "the directory merely exists" heuristic across all candidate dirs.
    return (LegacyGetLibs(), LegacyGetIncludes());
}

# --- Attempts to compile & link a small X11/XTest program with the given
#     (optional) include/lib dirs. Returns true if it succeeds. Does not
#     require a running/reachable X server -- this only needs to link. ---
sub CanBuildX11Test {
    my ($inc, $lib) = @_;

    my $dir = eval { File::Temp::tempdir(CLEANUP => 1) };
    return 0 unless defined $dir;

    my $src = File::Spec->catfile($dir, 'x11guitest_probe.c');
    my $exe = File::Spec->catfile($dir, 'x11guitest_probe' . ($Config{_exe} || ''));

    open(my $fh, '>', $src) or return 0;
    print $fh <<'C_SRC';
#include <X11/Xlib.h>
#include <X11/extensions/XTest.h>
int main(void) {
    Display *d = XOpenDisplay((char *)0);
    int ev = 0, er = 0, maj = 0, min = 0;
    XTestQueryExtension(d, &ev, &er, &maj, &min);
    return 0;
}
C_SRC
    close($fh);

    my $cc      = $Config{cc}       || 'cc';
    my $ccflags = $Config{ccflags}  || '';
    my $ldflags = $Config{ldflags}  || '';
    my $incflag = $inc ? "-I$inc" : '';
    my $libflag = $lib ? "-L$lib" : '';
    my $devnull = File::Spec->devnull;

    my $ok = system(
        "$cc $ccflags $incflag \"$src\" -o \"$exe\" $ldflags $libflag -lX11 -lXtst "
        . ">$devnull 2>&1"
    ) == 0;

    return ($ok && -x $exe) ? 1 : 0;
}

# --- Tries pkg-config (or pkgconf) for x11/xtst. Returns (libs, cflags) or
#     an empty list if unavailable/unusable. ---
sub TryPkgConfig {
    my $pkgconfig = _WhichProg('pkg-config') || _WhichProg('pkgconf');
    return () unless $pkgconfig;

    my $devnull = File::Spec->devnull;
    return () unless system("$pkgconfig --exists x11 xtst >$devnull 2>&1") == 0;

    my $libs = `$pkgconfig --libs x11 xtst 2>$devnull`;
    my $cflags = `$pkgconfig --cflags x11 xtst 2>$devnull`;
    return () unless defined $libs && defined $cflags;
    chomp($libs, $cflags);
    return () unless length $libs;

    return ($libs, $cflags);
}

# --- Legacy fallback: was GetLibs()/GetIncludes(). Only used when neither
#     pkg-config nor a compile probe can confirm a working combination. ---
sub LegacyGetLibs {
    my @found;
    for my $profile (@X11_PROFILES) {
        my (undef, $lib) = @$profile;
        push @found, "-L$lib" if $lib && -d $lib;
    }
    push @found, '-lXtst', '-lX11';
    return join(' ', @found);
}

sub LegacyGetIncludes {
    my %seen;
    my @found;
    for my $profile (@X11_PROFILES) {
        my ($inc) = @$profile;
        next unless $inc && -d $inc && !$seen{$inc}++;
        push @found, "-I$inc";
    }
    return join(' ', @found);
}


# --- Appends custom target to generated Makefile ---
# FORCE is used as a POSIX-compliant substitute for .PHONY across traditional Unix makes
sub MY::postamble {
    return <<'MAKE_FRAG';
docs : FORCE
	$(PERL) Makefile.PL --build-docs

FORCE:
MAKE_FRAG
}


# Helper routine callable via "make docs"
sub BuildDocs {
    my $podfile = 'GUITest.pm';
    my $tools   = _FindPodTools();

    unless ($tools->{podchecker} && $tools->{pod2text}) {
        print "Required POD tools (podchecker/pod2text) not found. Skipping docs.\n";
        return 0;
    }

    if (system("$tools->{podchecker} $podfile") != 0) {
        print "POD validation failed. Documentation generation aborted.\n";
        return 0;
    }

    print "Writing documentation for X11::GUITest...\n";

    unless (-d 'docs') {
        mkdir('docs', 0755) or die "Cannot create docs directory: $!\n";
    }

    if (system("$tools->{pod2text} $podfile docs/X11-GUITest.txt") == 0) {
        copy("docs/X11-GUITest.txt", "README");
    } else {
        print "Warning: pod2text failed.\n";
    }

    if ($tools->{pod2html}) {
        system("$tools->{pod2html} --infile=$podfile --outfile=docs/X11-GUITest.html") == 0
            or print "Warning: pod2html failed.\n";
    }

    # Portable cleanup of pod2html working files
    for my $f ('pod2htmd.tmp', 'pod2htmi.tmp') {
        unlink $f if -e $f;
    }

    return 1;
}


sub _FindPodTools {
    my @tools = qw(podchecker pod2text pod2html);
    my %found;

    foreach my $tool (@tools) {
        my $path = _WhichProg($tool);
        $found{$tool} = $path if $path;
    }

    return \%found;
}

# --- Locates a program on PATH; prefers File::Which when available, else
#     does its own POSIX-style PATH search. Shared by _FindPodTools() and
#     TryPkgConfig(). ---
sub _WhichProg {
    my ($prog) = @_;

    eval {
        require File::Which;
        File::Which->import('which');
    };
    if (defined &which) {
        return which($prog);
    }

    my $sep = $Config{path_sep} || ':';
    foreach my $dir (split /\Q$sep\E/, $ENV{PATH} || '') {
        my $candidate = File::Spec->catfile($dir, $prog);
        return $candidate if -x $candidate && ! -d $candidate;
    }
    return undef;
}
