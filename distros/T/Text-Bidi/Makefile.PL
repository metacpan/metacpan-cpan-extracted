use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker;
use FFI::CheckLib 0.28 qw(check_lib_or_exit);

# A missing system dependency makes the distribution inapplicable to CPAN
# Testers. Exit successfully before generating a Makefile in that case.
check_lib_or_exit(lib => 'fribidi') unless $ENV{TEXT_BIDI_FRIBIDI_LIB};

my %WriteMakefileArgs;
%WriteMakefileArgs = (
                       'CONFIGURE_REQUIRES' => {
                                                 'FFI::CheckLib' => '0.28',
                                                 'ExtUtils::MakeMaker' => '0'
                                               },
                       'ABSTRACT' => 'Unicode bidi algorithm using libfribidi',
                       'VERSION' => '3.02',
                       'DISTNAME' => 'Text-Bidi',
                       'EXE_FILES' => [
                                        'bin/fribidi.pl'
                                      ],
                       'TEST_REQUIRES' => {
                                            'Test::More' => '0',
                                            'File::Spec' => '0',
                                            'Symbol' => '0',
                                            'File::Temp' => '0',
                                            'ExtUtils::MakeMaker' => '0',
                                            'lib' => '0',
                                            'Cwd' => '0',
                                            'utf8' => '0',
                                            'charnames' => '0',
                                            'IO::Handle' => '0',
                                            'Data::Dumper' => '0',
                                            'IPC::Open3' => '0',
                                            'File::Basename' => '0'
                                          },
                       'AUTHOR' => 'Moshe Kamensky <kamensky@cpan.org>',
                       'MIN_PERL_VERSION' => '5.010000',
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'PREREQ_PM' => {
                                        'version' => '0.77',
                                        'Encode' => '0',
                                        'warnings' => '0',
                                        'Getopt::Long' => '0',
                                        'FFI::Platypus::Buffer' => '0',
                                        'Carp' => '0',
                                        'Tie::Array' => '0',
                                        'integer' => '0',
                                        'Exporter' => '0',
                                        'overload' => '0',
                                        'open' => '0',
                                        'FFI::Platypus' => '2.00',
                                        'base' => '0',
                                        'FFI::CheckLib' => '0.28',
                                        'strict' => '0'
                                      },
                       'LICENSE' => 'perl',
                       'NAME' => 'Text::Bidi'
                     );


# Dist::Zilla supplies release metadata; a checkout also builds directly.
%WriteMakefileArgs = (
    NAME => 'Text::Bidi',
    VERSION => '0.00',
    MIN_PERL_VERSION => '5.010000',
    CONFIGURE_REQUIRES => { 'FFI::CheckLib' => '0.28' },
    PREREQ_PM => {
        'FFI::CheckLib' => '0.28',
        'FFI::Platypus' => '2.00',
        'version' => '0.77',
    },
    TEST_REQUIRES => { 'Test::More' => 0 },
    %WriteMakefileArgs,
    # Ignore generated C files left over from a former SWIG checkout.
    XS => {},
    C => [],
    OBJECT => '',
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
    my $br = $WriteMakefileArgs{BUILD_REQUIRES} ||= {};
    for my $mod (keys %$tr) {
        $br->{$mod} = $tr->{$mod}
            unless exists $br->{$mod} && $br->{$mod} >= $tr->{$mod};
    }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
    my $br = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    my $pp = $WriteMakefileArgs{PREREQ_PM} ||= {};
    for my $mod (keys %$br) {
        $pp->{$mod} = $br->{$mod}
            unless exists $pp->{$mod} && $pp->{$mod} >= $br->{$mod};
    }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
