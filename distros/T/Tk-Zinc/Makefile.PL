use 5.008;
use Tk;
use Config;
use Tk::Config;
use ExtUtils::MakeMaker;
use strict;

my $TkLibDir = $Tk::library;
my $platform = $Tk::platform;

my $VERSION = 3.307;


if (!$TkLibDir)
{
    print STDERR "==================================================================\n";
    print STDERR "Could not find the Perl/Tk (pTk) library.\n";
    print STDERR "Please, install first Perl/Tk interface before installing Tk::Zinc\n";
    print STDERR "==================================================================\n";
    die;
}


print "Configuring version $VERSION for $platform platform...\n";
print "Using $TkLibDir as Tk library...\n";

my @GENERIC_C = ('Tabular.c', 'Rectangle.c', 'Arc.c', 'Curve.c',
         'Item.c', 'PostScript.c', 'Attrs.c', 'Draw.c', 'Geo.c', 'List.c',
         'perfos.c', 'Transfo.c', 'Group.c', 'Icon.c', 'Text.c', 'Image.c', 'Color.c',
         'Field.c', 'Triangles.c', 'Viewport.c', 'WindowUtils.c', 'Window.c', 'tkZinc.c',
         'ZincGlew.c');

my @ATC_C = ('OverlapMan.c', 'Track.c', 'Reticle.c', 'Map.c', 'MapInfo.c');

my @WIN_C = ('WinPort.c');

my @C;

my $WIN = ($platform =~ /win/i);

push @C, @GENERIC_C;

my $NeededLibs = ['-L/usr/X11R6/lib -lXext -lX11 -lGLU -lGL -L.'];

if ($WIN) {
    push @C, @WIN_C;
    $NeededLibs = ['-lglu32 -lopengl32'];
}
my $ZincObj = "Zinc" . $Config{"_o"};

my $INC = "-I. -Ithird_party/glew/include -I$TkLibDir -I$TkLibDir/pTk -I$TkLibDir/X11";

unless ($WIN) {
    $INC .= " -I/usr/X11R6/include";
}

#For some reason which the author of ExtUtils::MM_Unix forget, Unix machines like to have
#PERL_DL_NONLAZY set for tests. This is FALSE for TkZinc.

if ($] >= 5.008000) {
    *ExtUtils::MM_Unix::test_via_harness = sub {
        my($self, $perl, $tests) = @_;
        #return $self->SUPER::test_via_harness("PERL_DL_NONLAZY=1 $perl", $tests);
        # I should use the SUPER method, but this needs some import tunning...
        return ExtUtils::MM_Any::test_via_harness($self, $perl, $tests);
    };

    #Again, the PERL_DL_NONLAZY thing.
    *ExtUtils::MM_Unix::test_via_script = sub {
        my($self, $perl, $script) = @_;
        #return $self->SUPER::test_via_script("PERL_DL_NONLAZY=1 $perl", $script);
        # I should use the SUPER method, but this needs some import tunning...
        return ExtUtils::MM_Any::test_via_script($self, $perl, $script);
    };
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'ABSTRACT'        => 'a canvas offering groups, tranformations, transparency, color gradient...',
    'AUTHOR'          => 'Patrick Lecoanet <lecoanet@cena.fr>',
    'NAME'            => 'Tk::Zinc',
    'PREREQ_PM'       => {
        'Tk' => 800.004,
        'ExtUtils::MakeMaker' => '6.98',
    },
    'TEST_REQUIRES'   => {
        'Test::More' => '0.98',
    },
    'LIBS'            => $NeededLibs, 
    'OPTIMIZE'        => &optimize,
    'DEFINE'          => &get_flags,
    'INC'             => $INC,
    'C'               => [@C],
    'VERSION'         => $VERSION,
    'XS_VERSION'      => $Tk::Config::VERSION,
    'XS'              => {'Zinc.xs' => 'Zinc.c'},
    'linkext'         => {LINKTYPE => 'dynamic'},
    'depend'          => {
        $ZincObj => '$(O_FILES) Zinc.c',
        'ZincGlew$(OBJ_EXT)' => 'third_party/glew/src/glew.c third_party/glew/include/GL/glew.h third_party/glew/include/GL/wglew.h third_party/glew/include/GL/glxew.h',
        'tkZinc$(OBJ_EXT)' => 'third_party/glew/include/GL/glew.h',
    },
    'LDFROM'          => "\$(O_FILES) $ZincObj",
    'MIN_PERL_VERSION'  => 5.008,
    'META_MERGE'      => {
        'resources'     => {
            'repository' => 'https://github.com/asb-capfan/TkZinc',
        },
        'configure_requires' => {
            'Tk' => 0,
        },
    },
);

sub optimize {
    foreach my $arg (@ARGV) {
        if ($arg =~ /(enable-symbols)/i) {
            return "-g";
        }
    }
    return "-O";
}

sub get_flags {
    my %DEF_FLAGS = (
        'GL'        => 1,
        'SHAPE'     => 1,
        'ATC'       => 1
    );
    
    foreach my $arg (@ARGV) {
        print "$arg ....\n";
        my ($name, $value) = split(/[=]+/, $arg);
        if ($name =~ /(with-gl)/i) {
            if ($value =~ /no/i) {
                $DEF_FLAGS{'GL'} = 0;
            }
        }
        elsif ($name =~ /(with-atc)/i) {
            if ($value =~ /no/i) {
                $DEF_FLAGS{'ATC'} = 0;
            }
        }
        elsif ($name =~ /(with-shape)/i) {
            if ($value =~ /no/i) {
                $DEF_FLAGS{'SHAPE'} = 0;
            }
        }
    }
    
    my $defines = "-DPTK -DTKZINC_PRIVATE_GLEW -DPACKAGE_VERSION=\\\"$VERSION\\\"";

    if ($WIN) {
        #
        # No shape extension on Windows (planned later).
        $DEF_FLAGS{'SHAPE'} = 0;
        #
        # Visual C++ does not define __STDC__ by default. GCC already does.
        if ($Config{'cc'} =~ /(?:^|[\\\/\s"])cl(?:\.exe)?(?=["\s]|$)/i) {
            $defines .= ' -D__STDC__';
        }
    }

    print "Configuring with:\n    ";
    foreach my $flag (keys %DEF_FLAGS) {
        print "$flag=", $DEF_FLAGS{$flag} ? 'ok' : 'no', " ";
        if ($DEF_FLAGS{$flag}) {        
            $defines = $defines . " " . "-D$flag";
            if ($flag eq 'ATC') {
                push @C, @ATC_C;
            }
        }
    }
    if ($Tk::VERSION =~ /^800/) {
        $defines .= " -DPTK_800";
        print "PTK=800";
    } else {
        print "PTK=804";
    }
    print "\n";
    return $defines;
}

#
# For the demo
#
# perl -Mblib demos/zinc-demos

