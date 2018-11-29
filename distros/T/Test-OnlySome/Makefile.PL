use 5.012;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# Get the filename of the Perl interpreter running this. {{{1
# Modified from perlvar.
# The -x test is for cygwin or other systems where $Config{perlpath} has no
# extension and $Config{_exe} is nonempty.  E.g., symlink perl->perl5.10.1.exe.
# There is no "perl.exe" on such a system.
sub get_perl_filename {
    my $secure_perl_path = $Config{perlpath};
    if ($^O ne 'VMS') {
        $secure_perl_path .= $Config{_exe}
            unless (-x $secure_perl_path) ||
                            ($secure_perl_path =~ m/$Config{_exe}$/i);
    }
    return $secure_perl_path;
} # get_perl_filename() }}}1

my $secure_perl_path = get_perl_filename();

# Set up Makefile to generate README.md {{{1
{   package MY;

    # dist_core: make `dist` a :: target rather than a : target.
    sub dist_core {
        my $self = shift;
        my $text = $self->SUPER::dist_core(@_);
        $text =~ s/^dist\s*:[^:]/dist:: /m;
        return $text;
    } # MY::dist_core

    sub postamble {     # TODO also handle Windows nmake syntax (SET vs. export)
        # Note: pod2markdown is marked with a hyphen so that `make` can
        # succeed and generate META files even if Pod::Markdown is not yet
        # installed.
        return <<EOT;
authortest:
\tRELEASE_TESTING=1 prove -l xt

testhere:   # Run the tests from lib rather than blib
\tprove -lj4

README.md: lib/Test/OnlySome.pm
\t-pod2markdown \$< > \$@

all :: README.md
dist :: README.md

EOT

    } #postamble()
} #package MY }}}1

WriteMakefile(
    NAME             => 'Test::OnlySome',
    AUTHOR           => q{Christopher White <cxwembedded@gmail.com>},
    VERSION_FROM     => 'lib/Test/OnlySome.pm',
    ABSTRACT_FROM    => 'lib/Test/OnlySome.pm',
    LICENSE          => 'mit',
    PL_FILES         => {},

    MIN_PERL_VERSION => '5.012',    # required by Keyword::Declare
    CONFIGURE_REQUIRES => {
        'Config' => '0',
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Carp' => '0',
        'Exporter' => '0',
        'Import::Into' => '0',
        'parent' => '0',
        'Pod::Markdown' => '0',
        'rlib' => '0',
        'Test::More' => '0',
    },
    TEST_REQUIRES => {
        'constant' => '0',
        'Test::Fatal' => '0',
        'Test::Kit' => '2.14',
    },
    PREREQ_PM => {
        'Best' => '0.11',   # Because single-method imports work in 0.11+
        'Data::Dumper' => '0',
        #'File::Slurp' => '9999.19',     # because in this ver write_file
        #                                # works in the presence of signals
        'File::Spec' => '0',
        'Keyword::Declare'  => '0.001006',
        'Scalar::Util' => '1.39',
        'vars' => '0',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },

        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/cxw42/Test-OnlySome.git',
                web  => 'https://github.com/cxw42/Test-OnlySome',
            },
        },

        prereqs => {
            develop => {
                requires => {
                    'File::Grep' => '0',
                    'DateTime' => '0',
                },
            },
            runtime => {
                requires => {
                    'YAML' => '0',
                },
                recommends => {
                    'YAML::XS' => '0',
                },
            },
        },

    }, #META_MERGE
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-OnlySome-*' },
);

# vi: set fdm=marker fdl=0: #
