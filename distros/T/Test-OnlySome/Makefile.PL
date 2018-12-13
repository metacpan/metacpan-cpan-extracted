use 5.012;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# Module metadata {{{1
my $provides;
eval {
    require Module::Metadata;
    $provides = Module::Metadata->provides(version => '2', dir => 'lib');
        # Thanks to https://stackoverflow.com/a/28928985/2877364 by LEONT
};
# }}}1

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

# Set up Makefile to generate README.md and uninstall targets {{{1
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
\tRELEASE_TESTING=1 prove -lvj4 xt

testhere:   # Run the tests from lib rather than blib
\tprove -lj4

README.md: lib/Test/OnlySome.pm Makefile.PL
\t-pod2markdown \$< | \\
\t$secure_perl_path -ne 'print if /BUGS/; next if /INTERNALS/../BUGS/; print' \\
> \$@

all :: README.md
dist :: README.md

# Uninstallation: mimic what the normal "uninstall" target does, but actually
# carry out the actions.
# Note: this may leave empty directories in place, since the packlist only
# includes files.

ACTUALLY_UNINSTALL = "$secure_perl_path" -MExtUtils::Install -e 'uninstall(shift,1)' --

actually_uninstall :: actually_uninstall_from_\$(INSTALLDIRS)dirs
\t\$(NOECHO) \$(NOOP)

actually_uninstall_from_perldirs ::
\t-\$(ACTUALLY_UNINSTALL) "\$(PERL_ARCHLIB)/auto/\$(FULLEXT)/.packlist"

actually_uninstall_from_sitedirs ::
\t-\$(ACTUALLY_UNINSTALL) "\$(SITEARCHEXP)/auto/\$(FULLEXT)/.packlist"

actually_uninstall_from_vendordirs ::
\t-\$(ACTUALLY_UNINSTALL) "\$(VENDORARCHEXP)/auto/\$(FULLEXT)/.packlist"

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
    EXE_FILES       => [ 'bin/osprove' ],

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
        'App::Prove' => '0',
        'Capture::Tiny' => '0',
        'constant' => '0',
        'Exporter::Renaming' => '0',
        'Test::Fatal' => '0',
        'Test::Kit' => '2.14',
        'Test2::Tools::Compare' => '0',
    },
    PREREQ_PM => {
        'Best' => '0.11',   # Because single-method imports work in 0.11+
        'Data::Dumper' => '0',
        'File::Spec' => '0',
        'Getopt::Long' => '2.5',
        'Keyword::Declare'  => '0.001006',
        'List::Util::MaybeXS' => '1.500002',
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
                    'App::RewriteVersion' => '0',   # for perl-bump-version
                    'File::Globstar' => '0',
                    'File::Grep' => '0',
                    'DateTime' => '0',
                    'Module::Metadata' => '1.000016',
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

        $provides ? (provides => $provides) : (),

    }, #META_MERGE
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-OnlySome-*' },
);

# vi: set fdm=marker fdl=0: #
