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
    clean  => { FILES => 'Test-MockFile-*' },
    $ExtUtils::MakeMaker::VERSION >= 6.46
    ? (
        'META_MERGE' => {
            resources => {
                'license'    => 'http://dev.perl.org/licenses/',
                'homepage'   => 'http://github.com/toddr/YAML-Syck',
                'bugtracker' => 'https://github.com/toddr/YAML-Syck/issues',
                'repository' => 'http://github.com/toddr/YAML-Syck',
            }
        }
      )
    : (),
);

#-cc_files
