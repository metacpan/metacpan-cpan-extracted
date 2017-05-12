use 5.008001;

use strict;
use warnings;

use Config;
use ExtUtils::Depends;
use ExtUtils::MakeMaker;
use File::Copy 'copy';

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
    'B::Hooks::OP::Annotation' => '0.43',
    'B::Hooks::OP::Check'      => '0.18',
);

our %XS_DEPENDENCIES = ExtUtils::Depends->new('true', keys(%XS_PREREQUISITES))->get_makefile_vars();

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

            next if -f $want; # everything OK: next

            my $maybe = "$base.lib";

            next unless -f $maybe; # if neither file exists, either this one is elsewhere or we have a problem: next

            copy($maybe, $want); # .a is missing, but .lib exists, so just copy it over
        }
    }
}

ensure_activeperl_dep_files_exist($XS_DEPENDENCIES{LIBS});

WriteMakefile(
    NAME          => 'true',
    VERSION_FROM  => 'lib/true.pm',
    PREREQ_PM => {
        %XS_PREREQUISITES,
        'Devel::StackTrace' => '1.27',
    },
    ABSTRACT_FROM => 'lib/true.pm',
    AUTHOR        => 'chocolateboy <chocolate@cpan.org>',
    LIBS          => [''],
    DEFINE        => '',
    INC           => '-I.',
    OPTIMIZE      => $OPTIMIZE,
    (eval($ExtUtils::MakeMaker::VERSION) >= 6.46 ?
        (META_MERGE => {
            configure_requires => {
                'ExtUtils::Depends' => '0.304',
                %XS_PREREQUISITES
            },
            resources => {
                repository => 'http://github.com/chocolateboy/true',
            },
        })
        : ()
    ),
    (eval($ExtUtils::MakeMaker::VERSION) >= 6.31 ? (LICENSE => 'perl') : ()),
    %XS_DEPENDENCIES,
);
