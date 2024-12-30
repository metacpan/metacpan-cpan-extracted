# Makefile.PL for XML::Hash::XS.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# Copyright 2012-2021 Yuriy Ustushenko, all rights reserved.
#
# Derived from the module XML::LibXML
# Copyright 2001-2003 AxKit.com Ltd., 2002-2006 Christian Glahn, 2006-2009 Petr Pajas

use 5.008008;
use warnings;
use strict;
use lib qw(inc);
use Devel::CheckLib;
use ExtUtils::MakeMaker;
use Config;
use File::Spec;

$| = 0;

our $IS_VC = $Config{cc} eq 'cl';
our %PARAMS = parse_params();

my %WriteMakefileArgs = (
    NAME             => 'XML::Hash::XS',
    VERSION_FROM     => 'lib/XML/Hash/XS.pm',
    ABSTRACT_FROM    => 'lib/XML/Hash/XS.pm',
    AUTHOR           => 'Yuriy Ustushenko <yuriy.ustushenko@gmail.com>',
    test             => {
        TESTS => 't/*.t'. ($ENV{AUTHOR_TESTING} ? ' xt/*.t' : '')
    },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            license     => 'http://dev.perl.org/licenses/',
            homepage    => 'https://github.com/yoreek/XML-Hash-XS',
            repository => {
                type => 'git',
                url  => 'https://github.com/yoreek/XML-Hash-XS.git',
                web  => 'https://github.com/yoreek/XML-Hash-XS',
            },
            bugtracker => {
                web => 'https://github.com/yoreek/XML-Hash-XS/issues',
            },
        },
    },
    META_ADD         => {
        prereqs => {
            configure => {
                requires => {
                    'ExtUtils::MakeMaker' => 0,
                    'Config'              => 0,
                    'File::Spec'          => 0,
                },
            },
            build => {
                requires => {
                    'ExtUtils::MakeMaker' => 0,
                    'Config'              => 0,
                    'File::Spec'          => 0,
                },
            },
            runtime => {
                requires => {
                    'Exporter'            => 5.57,
                    'base'                => 0,
                    'XSLoader'            => 0,
                },
            },
            test => {
                requires => {
                    'Test::More'      => 0,
                    'Data::Dumper'    => 0,
                },
            },
        },
    },
    MIN_PERL_VERSION => 5.008008,
    LICENSE          => 'perl_5',
    CCFLAGS          => $Config{ccflags} . ( $IS_VC ? ' /Fosrc/' : ' -o $@' ),
    OBJECT           => q/$(O_FILES)/,
    XS               => { 'src/XS.xs' => 'src/XS.c',  },
    C                => [ 'src/XS.c', glob('src/*.c') ],
    H                => [ glob('src/*.h') ],
    clean            => { FILES => 'src/*.o* *.o* src/*.pdb *.pdb' },
    extra_config(),
);

my $eumm_version = eval $ExtUtils::MakeMaker::VERSION;

for (qw(configure build test runtime)) {
    my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
    next unless exists $WriteMakefileArgs{META_ADD}{prereqs}{$_}
             or exists $WriteMakefileArgs{$key};
    my $r = $WriteMakefileArgs{$key} = {
        %{$WriteMakefileArgs{META_ADD}{prereqs}{$_}{requires} || {}},
        %{delete $WriteMakefileArgs{$key} || {}},
    };
    defined $r->{$_} or delete $r->{$_} for keys %$r;
}

$WriteMakefileArgs{BUILD_REQUIRES} = {
    %{$WriteMakefileArgs{BUILD_REQUIRES} || {}},
    %{delete $WriteMakefileArgs{TEST_REQUIRES}}
} if $eumm_version < 6.63_03;

$WriteMakefileArgs{PREREQ_PM} = {
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{delete $WriteMakefileArgs{BUILD_REQUIRES}}
} if $eumm_version < 6.55_01;

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    if $eumm_version < 6.51_03;

delete @WriteMakefileArgs{qw(META_ADD META_MERGE)}
    if $eumm_version < 6.46;

delete $WriteMakefileArgs{MIN_PERL_VERSION}
    if $eumm_version < 6.48;

delete $WriteMakefileArgs{LICENSE}
    if $eumm_version < 6.31;

WriteMakefile(%WriteMakefileArgs);

sub extra_config {
    my $available_libs = get_available_libs();

    my (%config, %summary_config);
    my @options = qw(lib libpath incpath);

    # remove unneded libxml2
    delete $available_libs->{xml2} unless exists $available_libs->{'XML::LibXML'};

    foreach my $lib_config (values %$available_libs) {
        foreach my $option (@options) {
            my $value = $lib_config->{$option} or next;
            $value = [ split(/\s+/, $value) ] unless ref $value;
            $config{$option}{$_} = 1 for @$value;
        }
    }
    if ( $PARAMS{LIBS} ) {
        $summary_config{LIBS} = [ $PARAMS{LIBS} ];
    }
    else {
        my @libs = (
            # order is important!
            ( map { "-L$_" } keys %{ $config{libpath} || {} } ),
            ( map {
                $IS_VC && $_ !~ /\.lib$/ ? "-l$_.lib" : "-l$_"
              } keys %{ $config{lib} || {} }
            ),
        );
        $summary_config{LIBS} = [$Config::Config{ldflags} || '', @libs]
            if scalar @libs;
    }

    if ( $PARAMS{INC} ) {
        $summary_config{INC} = [ $PARAMS{INC} ];
    }
    else {
        my @inc = map { "-I$_" } keys %{ $config{incpath} || {} };
        $summary_config{INC} = \@inc if scalar @inc;
    }

    my @define = map { s/:/_/g; "-DXH_HAVE_" . uc($_) } keys %$available_libs;
    $summary_config{DEFINE} = \@define if scalar @define;

    # convert array to string
    $summary_config{$_} = join(' ', @{ $summary_config{$_} }) for keys %summary_config;

    # CCFLAGS
    $summary_config{CCFLAGS}  = ( $Config{ccflags} || '' ) . ( $IS_VC ? ' /Fosrc/' : ' -o $@' );
    $summary_config{CCFLAGS} .= ' -g -Wall -Werror -Wextra -pedantic -Wno-clobbered -std=c99 -DPERL_GCC_PEDANTIC -DWITH_DEBUG -O0'
        if $PARAMS{DEBUG};
    $summary_config{CCFLAGS} .= ' -DWITH_TRACE'
        if $PARAMS{DEBUG} && $PARAMS{TRACE};

    # Fix from Glib module.
    # On OpenBSD, any program that directly or indirectly wants to load
    # libpthread.so must do so from the start.  But when perl is built without
    # ithreads, it will also most likely not be compiled with "-pthread".  When
    # libglib/libgobject then go and try to load libpthread.so, the loader will
    # error out.
    if ($^O =~ /^openbsd|netbsd$/
        && $Config::Config{ldflags} !~ m/-pthread\b/
        && $Config::Config{ccflags} !~ m/-pthread\b/) {
        warn " ***\n *** on OpenBSD, we either need perl linked with '-pthread',\n",
             " ***   or we need to set LD_PRELOAD=libpthread.so; doing the latter now...\n ***\n";
        $summary_config{macro} = { FULLPERLRUN => 'LD_PRELOAD=/usr/lib/libpthread.so $(FULLPERL)' };
    }

    return %summary_config;
}

sub get_available_libs {
    my @COMMON_LIB_PATH = (
        '/usr/lib',
        '/usr/local/lib',
        '/usr/pkg/lib',
        '/opt/local/lib',
    );

    my @COMMON_INC_PATH = (
        '/usr/include',
        '/usr/local/include',
        '/usr/pkg/include',
        '/opt/local/include',
    );

    my @REQUIRED_LIBS = (
        {
            perl      => 1,
            name      => 'XML::LibXML',
            version   => 1.62,
            mandatory => 0,
        },
        {
            name      => 'xml2',
            mandatory => 0,
            configs   => [
                {
                    lib     => sub {
                        my $results = $PARAMS{WIN32} ? undef : backtick(
                            join('/bin/', grep { $_ } ($ENV{XMLPREFIX} || $PARAMS{XMLPREFIX}, 'xml2-config')),
                            '--libs',
                        );
                        $results ? [ map { substr($_, 2) } grep { $_ =~ /^-l/ } split(/\s+/, $results) ] : undef;
                    },
                    libpath => sub {
                        my $results = $PARAMS{WIN32} ? undef : backtick(
                            join('/bin/', grep { $_ } ($ENV{XMLPREFIX} || $PARAMS{XMLPREFIX}, 'xml2-config')),
                            '--libs',
                        );
                        $results ? [ map { substr($_, 2) } grep { $_ =~ /^-L/ } split(/\s+/, $results) ] : undef;
                    },
                    incpath => sub {
                        my $results = $PARAMS{WIN32} ? undef : backtick(
                            join('/bin/', grep { $_ } ($ENV{XMLPREFIX} || $PARAMS{XMLPREFIX}, 'xml2-config')),
                            '--cflags',
                        );
                        $results ? [ map { substr($_, 2) } grep { $_ =~ /^-I/ } split(/\s+/, $results) ] : undef;
                    },
                    header  => 'libxml/parser.h',
                },
                {
                    lib     => 'xml2 m z',
                    libpath => \@COMMON_LIB_PATH,
                    incpath => [
                        @COMMON_INC_PATH,
                        '/usr/include/libxml2',
                        '/usr/local/include/libxml2',
                        '/usr/pkg/include/libxml2',
                        '/opt/local/include/libxml2',
                    ],
                    header  => 'libxml/parser.h',
                },
            ],
        },
        {
            name    => 'iconv',
            configs => [
                {
                    lib      => 'c',
                    header   => 'iconv.h',
                    function => 'iconv_t iconv = iconv_open("UTF-8", "UTF-8");(void) iconv_close(iconv);return 0;',
                },
                {
                    lib      => 'iconv',
                    header   => 'iconv.h',
                    function => 'iconv_t iconv = iconv_open("UTF-8", "UTF-8");(void) iconv_close(iconv);return 0;',
                },
            ],
        },
        {
            name    => 'icu',
            configs => [
                {
                    lib     => sub {
                        my $results = $PARAMS{WIN32} ? undef : backtick('icu-config', '--ldflags-libsonly');
                        $results ? [ map { substr($_, 2) } grep { $_ =~ /^-l/ } split(/\s+/, $results) ] : undef;
                    },
                    libpath => sub {
                        my $results = $PARAMS{WIN32} ? undef : backtick('icu-config', '--ldflags-searchpath');
                        $results ? [ map { substr($_, 2) } grep { $_ =~ /^-L/ } split(/\s+/, $results) ] : undef;
                    },
                    incpath => sub {
                        my $results = $PARAMS{WIN32} ? undef : backtick('icu-config', '--cppflags-searchpath');
                        $results ? [ map { substr($_, 2) } grep { $_ =~ /^-I/ } split(/\s+/, $results) ] : undef;
                    },
                    header  => [
                        'unicode/utypes.h',
                        'unicode/ucnv.h',
                    ],
                    function => 'UErrorCode  status = U_ZERO_ERROR;UConverter *uconv = ucnv_open("UTF-8", &status);ucnv_close(uconv);return 0;',
                },
                {
                    lib => 'icui18n icuuc icudata',
                    libpath => \@COMMON_LIB_PATH,
                    incpath => \@COMMON_INC_PATH,
                    header  => [
                        'unicode/utypes.h',
                        'unicode/ucnv.h',
                    ],
                    function => 'UErrorCode  status = U_ZERO_ERROR;UConverter *uconv = ucnv_open("UTF-8", &status);ucnv_close(uconv);return 0;',
                },
            ],
        },
    );

    my %libs;
    my @options = qw(lib libpath incpath header function);
    foreach my $info (@REQUIRED_LIBS) {
        my $lib = $info->{name};

        if ( $info->{perl} ) {
            my $ver = $info->{version} || '';
            print "Checking for '$lib'... ";
            eval "use $lib $ver";
            if (my $err = $@) {
                print "no\n";
                print $err if $PARAMS{DEBUG}
            }
            else {
                print "yes\n";
                $libs{$lib} = {};
            }
        }
        else {
            foreach my $lib_config (@{ $info->{configs} }) {
                my %config;

                @config{@options} = map {
                    my $results = $lib_config->{$_};
                    $results = ($results and ref($results) eq 'CODE') ? &$results() : $results;
                    ($results and $_ ne 'function' and !ref($results))
                        ? [ split(/\s+/, $results) ]
                        : $results
                    ;
                } @options;

                next unless $config{lib} || $config{perl_lib};

                print "Checking for '$lib'... ";

                delete $config{$_} for grep { !$config{$_} } keys %config;
                if ( $PARAMS{LIBS} ) {
                    delete $config{lib};
                    delete $config{libpath};
                    $config{LIBS} = $PARAMS{LIBS};
                }
                if ( $PARAMS{INC} ) {
                    delete $config{incpath};
                    $config{INC} = $PARAMS{INC};
                }

                if ( check_lib(debug => $PARAMS{DEBUG}, %config) ) {
                    print "yes\n";
                    $libs{$lib} = \%config;
                    last;
                }

                print "no\n";
            }
        }

        if ($info->{mandatory} && !$libs{$lib}) {
            print STDERR <<"DEATH";
'$lib' library not found
Try setting LIBS and INC values on the command line

Also, you may try to run perl Makefile.PL with the DEBUG=1 parameter
to see the exact reason why the detection of '$lib' installation
failed or why Makefile.PL was not able to compile a test program.
DEATH
            exit 1;
        }
    }

    return \%libs;
}

sub parse_params {
    my %params;
    @params{qw(DEBUG TRACE INC LIBS XMLPREFIX)} = ();

    @ARGV = grep {
        my ($key, $val) = split(/=/, $_, 2);
        if (exists $params{$key}) {
            $params{$key} = $val; 0
        } else { 1 }
    } @ARGV;

    $params{WIN32} = ($^O =~ /Win32/);
    if ( $params{WIN32} ) {
        $params{DEVNULL} = 'DEVNULL';
    }
    else {
        $params{DEVNULL} = eval { File::Spec->devnull };
        if ($@) { $params{DEVNULL} = '/dev/null' }
    }

    return %params;
}

sub backtick {
    my $command = join(' ', @_);
    if ($PARAMS{DEBUG}) {
        print "Cmd: $command \n";
        my $results = `$command`;
        if ($? != 0) {
            warn "Backticks call to '$command' failed";
            return;
        }
        chomp $results;
        return $results;
    }

    local *OLDOUT;
    local *OLDERR;

    open(OLDOUT, ">&STDOUT");
    open(OLDERR, ">&STDERR");
    open(STDOUT, ">$PARAMS{DEVNULL}");
    open(STDERR, ">$PARAMS{DEVNULL}");
    my $results = `$command`;
    my $retval = $?;
    open(STDOUT, ">&OLDOUT");
    open(STDERR, ">&OLDERR");
    if ($retval != 0) {
        if ($PARAMS{DEBUG}) {
            warn "backticks call to '$command' failed";
        }
        return;
    }
    chomp $results;
    return $results;
}

package MY;

# Fix bug occurs while using multiple job compile:
# gcc: error: xh_buffer.c: No such file or directory
# Replace $* to $<
# $*: dir/file.o -> file.c
# $<: dir/file.o -> dir/file.c
sub c_o {
    my $inherited = shift->SUPER::c_o(@_);
    $inherited =~ s/\$\*.*/\$</g;
    $inherited;
}
