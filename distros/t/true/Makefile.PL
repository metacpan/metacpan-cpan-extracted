use 5.008001;

use strict;
use warnings;

use Config;
use ExtUtils::Depends;
use ExtUtils::MakeMaker;
use File::Copy 'copy';

our $EUMM_VERSION = eval($ExtUtils::MakeMaker::VERSION);
our $OPTIMIZE;

if ($Config{gccversion}) {
    $OPTIMIZE = '-O3 -Wall -W';
    $OPTIMIZE .= ' -g -Wextra -Wdeclaration-after-statement' if (-d 'dev');
} elsif ($Config{osname} eq 'MSWin32') {
    $OPTIMIZE = '-O2 -W4';
} else {
    $OPTIMIZE = $Config{optimize};
}

our %XS_PREREQUISITES = (
    'B::Hooks::OP::Annotation' => '0.44',
    'B::Hooks::OP::Check'      => '0.22',
);

our %XS_DEPENDENCIES = ExtUtils::Depends->new(
    'true',
    keys(%XS_PREREQUISITES)
)->get_makefile_vars();

# test dependencies
our %BUILD_REQUIRES;

# Function::Parameters requires perl >= v5.14.0
if ($] >= 5.014000) {
    %BUILD_REQUIRES = (
        # https://rt.cpan.org/Ticket/Display.html?id=124745
        'Moo'                  => '2.003004',
        'Function::Parameters' => '2.001003',
    );
}

sub ensure_activeperl_dep_files_exist($) {
    return if $^O ne 'MSWin32';
    return if $Config{make} !~ /dmake/;
    return if $Config{cc} !~ /gcc/;
    return if $Config{cf_email} !~ /ActiveState/;

    my $libs = shift;
    my @libs = split ' ', $libs;
    my @dirs  = grep { /^-L.+/ } @libs;
    my @files = grep { /^-l.+/ } @libs;

    s/^-L// for @dirs;
    s/^-l// for @files;

    for my $dir (@dirs) {
        for my $file (@files) {
            my $base = "$dir/$file";
            my $want = "$base.a";
            my $maybe = "$base.lib";

            # everything OK: next
            next if -f $want;

            # if neither file exists, either this one is elsewhere
            # or we have a problem: next
            next unless -f $maybe;

            # .a is missing, but .lib exists, so just copy it over
            copy($maybe, $want);
        }
    }
}

ensure_activeperl_dep_files_exist($XS_DEPENDENCIES{LIBS});

my %META = (
    NAME          => 'true',
    VERSION_FROM  => 'lib/true.pm',
    PREREQ_PM => {
        %XS_PREREQUISITES,
        'Devel::StackTrace' => '2.03',
    },
    ABSTRACT_FROM => 'lib/true.pm',
    AUTHOR        => 'chocolateboy <chocolate@cpan.org>',
    LIBS          => [''],
    DEFINE        => '',
    INC           => '-I.',
    OPTIMIZE      => $OPTIMIZE,
    %XS_DEPENDENCIES,
);

if ($EUMM_VERSION >= 6.31) {
    $META{LICENSE} = 'artistic_2';
}

if ($EUMM_VERSION >= 6.46) {
    $META{META_MERGE} = {
        configure_requires => {
            'ExtUtils::Depends' => '0.405',
            %XS_PREREQUISITES
        },
        dynamic_config => 1, # [1]
        resources => {
            repository => 'https://github.com/chocolateboy/true',
            bugtracker => 'https://github.com/chocolateboy/true/issues',
        },
    };
}

# [1] make sure this script is always run (to correctly handle the
# conditional test dependency on Function::Parameters). this avoids signaling to
# clients that the static metadata in META.yml or META.json is sufficient for
# every build
#
# http://blogs.perl.org/users/neilb/2017/04/an-introduction-to-distribution-metadata.html
# https://github.com/Perl-Toolchain-Gang/CPAN-Meta/issues/112

if ($EUMM_VERSION >= 6.48) {
    $META{MIN_PERL_VERSION} = '5.008';
}

if ($EUMM_VERSION >= 6.55_03) {
    $META{BUILD_REQUIRES} = \%BUILD_REQUIRES;
} else {
    $META{PREREQ_PM} = { %{ $META{PREREQ_PM} || {} }, %BUILD_REQUIRES };
}

WriteMakefile(%META);
