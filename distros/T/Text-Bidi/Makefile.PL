use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs;
%WriteMakefileArgs = (
                       'MIN_PERL_VERSION' => '5.010000',
                       'VERSION' => '3.01',
                       'NAME' => 'Text::Bidi',
                       'TEST_REQUIRES' => {
                                            'utf8' => '0',
                                            'File::Temp' => '0',
                                            'ExtUtils::MakeMaker' => '0',
                                            'File::Basename' => '0',
                                            'IO::Handle' => '0',
                                            'IPC::Open3' => '0',
                                            'Cwd' => '0',
                                            'Symbol' => '0',
                                            'charnames' => '0',
                                            'Test::More' => '0',
                                            'Data::Dumper' => '0',
                                            'File::Spec' => '0',
                                            'lib' => '0'
                                          },
                       'PREREQ_PM' => {
                                        'Tie::Array' => '0',
                                        'open' => '0',
                                        'integer' => '0',
                                        'version' => '0.77',
                                        'warnings' => '0',
                                        'FFI::CheckLib' => '0.28',
                                        'FFI::Platypus::Buffer' => '0',
                                        'overload' => '0',
                                        'Encode' => '0',
                                        'Exporter' => '0',
                                        'Getopt::Long' => '0',
                                        'Carp' => '0',
                                        'strict' => '0',
                                        'base' => '0',
                                        'FFI::Platypus' => '2.00'
                                      },
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '0'
                                               },
                       'DISTNAME' => 'Text-Bidi',
                       'LICENSE' => 'perl',
                       'AUTHOR' => 'Moshe Kamensky <kamensky@cpan.org>',
                       'EXE_FILES' => [
                                        'bin/fribidi.pl'
                                      ],
                       'ABSTRACT' => 'Unicode bidi algorithm using libfribidi',
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 }
                     );


# Dist::Zilla supplies release metadata; a checkout also builds directly.
%WriteMakefileArgs = (
    NAME => 'Text::Bidi',
    VERSION => '0.00',
    MIN_PERL_VERSION => '5.010000',
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
