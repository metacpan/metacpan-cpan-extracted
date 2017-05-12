use 5.008;

use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config qw(%Config);
use Getopt::Long qw(GetOptions);
use File::Basename qw(fileparse);
use Alien::TinyCC;

my $debug = $ENV{DEBUG};

GetOptions(
    'debug|d' => \$debug,
);


our $OPTIMIZE;

if ($Config{gccversion}) {
    $OPTIMIZE = '-O3 -Wall -W';
} elsif ($Config{osname} eq 'MSWin32') {
    $OPTIMIZE = '-O2 -W4';
} else {
    $OPTIMIZE = $Config{optimize};
}

if ($debug) {
    $OPTIMIZE .= ' -g';
}

my @tcc_runtime_files;
push @tcc_runtime_files, 'typemap_func.h';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile1(
    MIN_PERL_VERSION => '5.008',
    META_MERGE => {
        resources => {
            repository => 'git://github.com/tsee/p5-XS-TCC.git'
        },
    },
    BUILD_REQUIRES => {
        'Test::More' => '0.88',
    },
    NAME              => 'XS::TCC',
    VERSION_FROM      => 'lib/XS/TCC.pm', # finds $VERSION
    PREREQ_PM         => {
        'XSLoader' => 0,
        'ExtUtils::ParseXS' => '3.21',
        'ExtUtils::Typemaps' => '3.21',
        'ExtUtils::Embed' => 0,
        'File::Spec' => 0,
        'File::ShareDir' => 0,
    },
    LICENSE => 'perl',
    ABSTRACT_FROM => 'lib/XS/TCC.pm',
    AUTHOR => 'Steffen Mueller <smueller@cpan.org>',
    Alien::TinyCC->EUMM_LIBS,
    Alien::TinyCC->EUMM_OBJECT,
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -I' . Alien::TinyCC->libtcc_include_path,
    OPTIMIZE          => $OPTIMIZE,
    META_MERGE => {
        configure_requires => {
            'Getopt::Long' => 0,
            'Cwd' => 0,
            'File::Spec' => 0,
            'File::Basename' => 0,
            'Alien::TinyCC' => '0.06',
        },
    },
);

sub MY::postamble {
    my $self = shift;
    my @ret;
    push @ret, <<HERE;

pure_all ::
	\$(MKPATH) \$(INST_LIB)/auto/share/dist/\$(DISTNAME)
HERE
        foreach my $if (0..$#tcc_runtime_files) {
            my $f = $tcc_runtime_files[$if];
            my $name = fileparse($f);
            push @ret, "\t\$(CP)  $f \$(INST_LIB)/auto/share/dist/\$(DISTNAME)/$name"
              . ($if != $#tcc_runtime_files ? " \\\n" : "\n");
        }
        push @ret, "\n";
    return join "", @ret;
}


sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.20. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;

    WriteMakefile(%params);
}

