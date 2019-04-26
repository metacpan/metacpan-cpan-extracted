use 5.020;
use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use File::Spec;

my $VERSION_FROM = File::Spec->catfile(qw(lib XML Axk.pm));
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
} # get_perl_filename()
# }}}1

my $secure_perl_path = get_perl_filename();

# Makefile customization {{{1
sub MY::postamble {     # TODO also handle Windows nmake syntax (SET vs. export)
    return <<EOT;

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

# Run author tests
authortest:
\tRELEASE_TESTING=1 prove -l xt

# Test without installing: run the tests from lib rather than blib
testhere: actually_uninstall
\t"$secure_perl_path" -Ilib -e 'use Test::Harness "runtests"; runtests \@ARGV;' -- t/*.t
EOT

} #postamble
# }}}1

# Main options for EUMM
my %opts = (
    NAME            => 'XML::Axk',
    AUTHOR          => q{Christopher White <cxwembedded@gmail.com>},
    VERSION_FROM    => $VERSION_FROM,
    ABSTRACT        => 'awk-like XML processor',
    LICENSE         => 'artistic_2',
    EXE_FILES       => [ File::Spec->catfile(qw(bin axk)) ],
    MIN_PERL_VERSION => '5.020',
    CONFIGURE_REQUIRES => {
        'Config' => '0',
        'ExtUtils::MakeMaker' => '0',
        'File::Spec' => '0',
        'strict' => '0',
        'version' => '0.77',
        'warnings' => '0',
    },
    TEST_REQUIRES => {
        'Capture::Tiny' => '0',
        'File::Spec' => '0',
        'Module::Loaded' => '0',
        'parent' => '0',
        'rlib' => '0',
        'Test::More' => '0.92',
        'Test::Exception' => '0',
        'Test::Kit' => '0',
        'Test::Class' => '0',
        'Test::Class::Load' => '0',
    },
    PREREQ_PM => {
        'Carp' => '0',
        'Data::Dumper' => '0',
        'Exporter' => '0',
        'Getopt::Long' => '2.50',
        'Hash::Util::FieldHash' => '0',
        'HTML::Selector::XPath' => '0',
        'Import::Into' => '0',
        'Object::Tiny' => '0',
        'Pod::Find' => '0',
        'Pod::Usage' => '0',
        'Tie::Array' => '0',
        'Tie::Hash' => '0',
        'Tie::Scalar' => '0',
        'vars' => '0',
        #'Web::Query' => '0',
        #'Web::Query::LibXML' => '0',
        'XML::DOM' => '0',
        'XML::DOM::XPath' => '0',
        'XML::Handler::BuildDOM' => '0',
        'XML::SAX::ParserFactory' => '0',
        #'XML::LibXML::jQuery' => '0',
            # Do I actually need full X::L::jQuery?
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'XML-Axk-*' },
    depend => { Makefile => '$(VERSION_FROM)' },

    META_MERGE => {
        'meta-spec' => { version => 2 },

        resources => {
            bugtracker => {
                web  => 'https://github.com/interpreters/axk/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/interpreters/axk.git',
                web  => 'https://github.com/interpreters/axk',
            },
        },

        prereqs => {
            develop => {
                requires => {
                    'App::RewriteVersion' => '0',   # for perl-bump-version
                    'Module::Metadata' => '1.000016',
                },
            },
        },

        x_authority => 'cpan:CXW',
        x_contributors => [
			# Use CPAN emails where possible, so MetaCPAN will pick them up.
			'Christopher White <cxw@cpan.org>',
        ],

        $provides ? (provides => $provides) : (),

    }, #META_MERGE
);

WriteMakefile(%opts);
# vi: set ts=4 sts=4 sw=4 et ai fdm=marker: #
