use 5.008;    #Devel::CheckLib
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib './inc';
use Devel::CheckLib;
use File::ShareDir::Install;
install_share dist => 'share';

use Config;
use File::Spec;

my $expat_libpath = $ENV{EXPATLIBPATH} || '';
my $expat_incpath = $ENV{EXPATINCPATH} || '';

my @replacement_args;

foreach (@ARGV) {
    if (/^EXPAT(LIB|INC)PATH=(.+)/) {
        if ( $1 eq 'LIB' ) {
            $expat_libpath = $2;
        }
        else {
            $expat_incpath = $2;
        }
    }
    elsif (/^LIBS=(.+)/) {
        # Support standard EUMM LIBS option: extract -L paths for expat detection
        my $libs_val = $1;
        if ( !$expat_libpath && $libs_val =~ /-L(\S+)/ ) {
            $expat_libpath = $1;
        }
        push( @replacement_args, $_ );
    }
    elsif (/^INC=(.+)/) {
        # Support standard EUMM INC option: extract -I paths for expat detection
        my $inc_val = $1;
        if ( !$expat_incpath && $inc_val =~ /-I(\S+)/ ) {
            $expat_incpath = $1;
        }
        push( @replacement_args, $_ );
    }
    else {
        push( @replacement_args, $_ );
    }
}

@ARGV = @replacement_args;

# --- Try to auto-detect expat via pkg-config or multiarch (GH#83 & GH#69) ---
if ( !$expat_libpath && !$expat_incpath ) {
    my $pkg_config = $ENV{PKG_CONFIG} || 'pkg-config';
    my $devnull    = File::Spec->devnull;

    # 1. Try comprehensive pkg-config search for headers and libs
    if ( my $pc_cflags = `$pkg_config --cflags expat 2>$devnull` ) {
        $expat_incpath = $1 if $pc_cflags =~ /-I(\S+)/;
    }

    if ( my $pc_libs = `$pkg_config --libs expat 2>$devnull` ) {
        $expat_libpath = $1 if $pc_libs =~ /-L(\S+)/;
    }

    # 2. Fallback: If libpath is still empty and not on Windows, try specialized paths
    if ( !$expat_libpath && $^O ne 'MSWin32' ) {
        # Check specific libdir variable from pkg-config
        chomp( my $libdir = `$pkg_config --variable=libdir expat 2>$devnull` || '' );

        if ( $libdir && -d $libdir ) {
            $expat_libpath = $libdir;
        }
        else {
            # Last resort: Debian/Ubuntu multiarch fallback
            chomp( my $multiarch = `gcc -print-multiarch 2>$devnull` || '' );
            my $multiarch_path = "/usr/lib/$multiarch";

            if ( $multiarch && -d $multiarch_path ) {
                if ( -f "$multiarch_path/libexpat.so" || -f "$multiarch_path/libexpat.a" ) {
                    $expat_libpath = $multiarch_path;
                }
            }
        }
    }
}

unless (
    check_lib(    # fill in what you prompted the user for here
        lib     => [qw(expat)],
        header  => ['expat.h'],
        incpath => $expat_incpath,
        ( $expat_libpath ? ( libpath => $expat_libpath ) : () ),
    )
) {
    warn <<'Expat_Not_Installed;';

Expat must be installed prior to building XML::Parser and I can't find
it in the standard library directories. Install 'expat-devel' (or
'libexpat1-dev') package with your OS package manager. See 'README'.

Or you can download expat from:

https://github.com/libexpat/libexpat

If expat is installed, but in a non-standard directory, then use the
standard ExtUtils::MakeMaker options to Makefile.PL:

    INC=-I/home/me/include    To set the directory in which to find expat.h

    LIBS="-L/home/me/lib -lexpat"  To set the directory in which to find libexpat

For example:

    perl Makefile.PL INC=-I/home/me/include LIBS="-L/home/me/lib -lexpat"

The legacy EXPATLIBPATH and EXPATINCPATH options are also supported:

    perl Makefile.PL EXPATLIBPATH=/home/me/lib EXPATINCPATH=/home/me/include

If expat is installed and pkg-config is available, you can also set:

    export PKG_CONFIG_PATH=/path/to/expat/lib/pkgconfig

and Makefile.PL will use pkg-config to find expat automatically.

Note that if you build against a shareable library in a non-standard location
you may (on some platforms) also have to set your LD_LIBRARY_PATH environment
variable at run time for perl to find the library.

Expat_Not_Installed;

    # exiting before Makefile generation silences CPANTesters reports
    # when expat is not available.
    exit 0;
}

if ( not $expat_libpath and $^O ne 'MSWin32' ) {
    require ExtUtils::Liblist;
    ($expat_libpath) = ExtUtils::Liblist->ext('-lexpat');
}

# Propagate resolved paths to Expat/Makefile.PL via environment
# (subdirectory Makefile.PLs run as separate processes)
$ENV{EXPATLIBPATH} = $expat_libpath if $expat_libpath;
$ENV{EXPATINCPATH} = $expat_incpath if $expat_incpath;

# Don't try to descend into Expat directory for testing

sub MY::test {
    my $self = shift;

    my $hold = delete $self->{DIR};
    my $ret  = $self->MM::test(@_);
    $self->{DIR} = $hold if defined($hold);
    $ret;
}

sub MY::postamble {
    my $self = shift;
    my @ret  = File::ShareDir::Install::postamble($self);
    return join "\n", @ret;
}

my $dist_version = MM->parse_version('Parser.pm');

WriteMakefile1(
    ABSTRACT_FROM    => 'Parser.pm',
    AUTHOR           => 'Clark Cooper (coopercc@netheaven.com)',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.008',
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        provides => {
            'XML::Parser' => {
                file    => 'Parser.pm',
                version => $dist_version,
            },
            'XML::Parser::Expat' => {
                file    => 'Expat/Expat.pm',
                version => $dist_version,
            },
            'XML::Parser::Style::Debug' => {
                file    => 'Parser/Style/Debug.pm',
            },
            'XML::Parser::Style::Objects' => {
                file    => 'Parser/Style/Objects.pm',
            },
            'XML::Parser::Style::Stream' => {
                file    => 'Parser/Style/Stream.pm',
            },
            'XML::Parser::Style::Subs' => {
                file    => 'Parser/Style/Subs.pm',
            },
            'XML::Parser::Style::Tree' => {
                file    => 'Parser/Style/Tree.pm',
            },
        },
        resources => {
            bugtracker => {
                web => 'https://github.com/cpan-authors/XML-Parser/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/cpan-authors/XML-Parser.git',
                web  => 'https://github.com/cpan-authors/XML-Parser',
            },
        },
        prereqs => {
            runtime => {
                recommends => {
                    'LWP::UserAgent' => 0,
                },
            },
        },
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'warnings'   => 0,
    },

    NAME         => 'XML::Parser',
    DIR          => [qw(Expat)],
    clean        => { FILES => 'assertlib*' },
    dist         => { COMPRESS => 'gzip', SUFFIX => '.gz' },
    VERSION_FROM => 'Parser.pm',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => 0,
        'File::ShareDir::Install' => '0.06',
    },
    PREREQ_PM => {
        'File::ShareDir' => 0,
    },
    $^O =~ /win/i
    ? (
        dist => {
            TAR      => 'ptar',
            TARFLAGS => '-c -C -f',
        },
      )
    : (),
);

sub WriteMakefile1 {    #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 0.23. Added by eumm-upgrade.
    my %params       = @_;
    my $eumm_version = $ExtUtils::MakeMaker::VERSION;
    $eumm_version = eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ( $params{AUTHOR} and ref( $params{AUTHOR} ) eq 'ARRAY' and $eumm_version < 6.5705 ) {
        $params{META_ADD}->{author} = $params{AUTHOR};
        $params{AUTHOR} = join( ', ', @{ $params{AUTHOR} } );
    }
    if ( $params{TEST_REQUIRES} and $eumm_version < 6.64 ) {
        $params{BUILD_REQUIRES} = { %{ $params{BUILD_REQUIRES} || {} }, %{ $params{TEST_REQUIRES} } };
        delete $params{TEST_REQUIRES};
    }
    if ( $params{BUILD_REQUIRES} and $eumm_version < 6.5503 ) {

        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM} = { %{ $params{PREREQ_PM} || {} }, %{ $params{BUILD_REQUIRES} } };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION}   if $eumm_version < 6.48;
    delete $params{META_MERGE}         if $eumm_version < 6.46;
    delete $params{META_ADD}           if $eumm_version < 6.46;
    delete $params{LICENSE}            if $eumm_version < 6.31;

    WriteMakefile(%params);
}

