use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

require "./inc/ExtUtils/HasCompiler.pm";

my $can_xs = ExtUtils::HasCompiler::can_compile_loadable_object( quiet => 1 ) ? 1 : 0;
if ( !$can_xs ) {
    print "Sorry! YAML::Syck requires a compiler in order to be built.\n";
    exit 1;
}

my $bad;
if ( eval { require YAML; $YAML::VERSION < 0.60 } ) {
    print "*** Pre-0.60 version of YAML.pm ($YAML::VERSION) detected.\n";
    $bad++;
}
if ( eval { require YAML::Syck; $YAML::Syck::VERSION < 0.60 } ) {
    print "*** Pre-0.60 version of YAML::Syck ($YAML::Syck::VERSION) detected.\n";
    $bad++;
}

if ($bad) {
    print << '_';

*** WARNING ***

YAML::Syck version >=0.60 breaks compatibility with earlier versions of
YAML::Syck and YAML.pm (<0.60) when serializing blessed references.

See the COMPATIBILITY file for more information.

_

    my $ans = prompt( "Continue installing YAML::Syck?", "y" );
    exit() unless $ans =~ /^y/i;
}

# One liner stolen from inc/Module/Install/Compiler.pm
my $c_files = join ' ', map { substr( $_, 0, -2 ) . $Config::Config{_o} } ( glob("*.c"), ( -e 'Syck.c' ? () : 'Syck.c' ) );

my $version = MM->parse_version('lib/YAML/Syck.pm');

WriteMakefile(
    NAME               => 'YAML::Syck',
    AUTHOR             => q{Todd Rinaldo <toddr@cpan.org>},
    VERSION_FROM       => 'lib/YAML/Syck.pm',
    ABSTRACT_FROM      => 'lib/YAML/Syck.pm',
    LICENSE            => 'MIT',
    PL_FILES           => {},
    MIN_PERL_VERSION   => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
        defined $ENV{'AUTOMATED_TESTING'} ? ( 'Devel::Leak' => 0 ) : (),

    },
    INC    => "-I.",
    OBJECT => $c_files,
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean  => { FILES => 'YAML-Syck-*' },
    $ExtUtils::MakeMaker::VERSION >= 6.46
    ? (
        'META_MERGE' => {
            'meta-spec' => { version => 2 },
            resources => {
                'license'    => ['https://dev.perl.org/licenses/'],
                'homepage'   => 'https://github.com/toddr/YAML-Syck',
                'bugtracker' => {
                    'web' => 'https://github.com/toddr/YAML-Syck/issues',
                },
                'repository' => {
                    'type' => 'git',
                    'url'  => 'https://github.com/toddr/YAML-Syck.git',
                    'web'  => 'https://github.com/toddr/YAML-Syck',
                },
            },
            provides => {
                'YAML::Syck' => {
                    file    => 'lib/YAML/Syck.pm',
                    version => $version,
                },
                'JSON::Syck' => {
                    file    => 'lib/JSON/Syck.pm',
                    version => $version,
                },
                'YAML::Dumper::Syck' => {
                    file    => 'lib/YAML/Dumper/Syck.pm',
                },
                'YAML::Loader::Syck' => {
                    file    => 'lib/YAML/Loader/Syck.pm',
                },
            },
        }
      )
    : (),
);

# Suppress make's built-in .y -> .c implicit rule.
# gram.c and gram.h are pre-generated and checked in;
# yacc/bison is only needed when gram.y changes.
sub MY::postamble {
    return <<'MAKE';
# gram.c and gram.h are pre-generated and checked in;
# yacc/bison is only needed when gram.y changes.
# Remove .y from the suffix list so make never infers a .y -> .c rule.
.SUFFIXES:
.SUFFIXES: .c .h .o .obj .xs

# Regenerate gram.c and gram.h from gram.y (requires bison >= 3.0).
# macOS ships bison 2.3; use Homebrew bison if available.
BISON = $(shell command -v /opt/homebrew/opt/bison/bin/bison 2>/dev/null || command -v /usr/local/opt/bison/bin/bison 2>/dev/null || command -v /opt/homebrew/bin/bison 2>/dev/null || command -v /usr/local/bin/bison 2>/dev/null || echo bison)
regen-grammar: gram.y
	$(BISON) -o gram.c -d gram.y
MAKE
}

#-cc_files
