# Copyright 2022 cPanel, LLC. (copyright@cpanel.net)
# Author: Felipe Gasper
#
# Copyright (c) 2022, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use ExtUtils::MakeMaker::CPANfile;
use ExtUtils::PkgConfig;
use ExtUtils::CBuilder;
use File::Temp;

my ($modversion, $libs, @iculibs, @inc_extra);

print "First let’s see if your pkg-config knows about “icu” …\n";

if ($libs = ExtUtils::PkgConfig->libs("icu")) {
    $modversion = ExtUtils::PkgConfig->modversion('icu');
    print "… found it! (ICU $modversion)\n";

    @iculibs = qw(icu);
}
else {
    my @LIBS = qw( i18n uc );
    #push @LIBS, 'io';   # debug

    print "Doesn’t look like it. How about “icu-$LIBS[0]” et al.?\n";

    @iculibs = map { "icu-$_" } @LIBS;
    $libs = ExtUtils::PkgConfig->libs("@iculibs");

    if ($libs) {
        $modversion = ExtUtils::PkgConfig->modversion($iculibs[0]);
        print "… found it! (ICU $modversion)\n";
    }
    else{
        die "Your pkg-config can’t find ICU. Is it installed?\n";
    }
}

my ($major_version) = ($modversion =~ m<\A([0-9]+)>);
if ($major_version >= 59) {
    print "Your ICU version ($modversion) needs C++11.\n";

    @inc_extra = (
        '-std=c++11',
        '-Wno-c++11-extensions',
        '-Wno-c++11-long-long',
    );

    if ($^V lt v5.20.0) {
        print "Your perl ($^V) is old enough that its headers conflict with\n";
        print "C++11’s user-defined literals. Disabling that feature …\n";

        # In pre-5.20 perls the header files don’t always have spaces
        # around macros like “UVxf”, which C++11 invalidated. So we need
        # to tell the compiler to allow that:
        push @inc_extra, (
            '-Wno-reserved-user-defined-literal',   # clang
            '-Wno-literal-suffix',                  # g++
        );
    }
}
else {
    print "Your ICU version ($modversion) doesn’t need C++11.\n";
}

my $cflags = ExtUtils::PkgConfig->cflags("@iculibs") || q<>;

print "cflags: $cflags\n";
print "libs: $libs\n";

my $cc = 'c++';

system $cc, '-v';

#my $basic_inc = "-Wall -I. -Werror=vla @inc_extra $cflags";
my $basic_inc = "-Wall -I. @inc_extra $cflags";

my @defines = _determine_defines($basic_inc, $libs);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Unicode::ICU',
    VERSION_FROM      => 'lib/Unicode/ICU.pm', # finds $VERSION
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Unicode/ICU.pm', # retrieve abstract from module
       AUTHOR         => [
            'cPanel, L.L.C. (CPANEL)',
        ],
      ) : ()
    ),
    LIBS              => $libs,
    DEFINE            => '',
    INC               => "@defines $basic_inc",
    LICENSE           => "perl_5",

    CC => $cc,
    LD => '$(CC)',

    XSOPT => '-C++',

    OBJECT => join(
        q< >,
        '$(BASEEXT)$(OBJ_EXT)',
        'unicode_icu.o',
        'unicode_icu_messagepattern.o',
    ),

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/cpanel/p5-Unicode-ICU.git',
                web => 'https://github.com/cpanel/p5-Unicode-ICU',
            },
            bugtracker => {
                web => 'https://github.com/cpanel/p5-Unicode-ICU/issues',
            },
        },
    },
);

sub _determine_defines {
    my $inc = shift;
    my $lflags = shift;

    my $builder = ExtUtils::CBuilder->new(
        config => {
            cc => "$cc $inc -Wno-unused-variable",
            ld => $cc,
        },
    );

    my @defines;

    my @checks = (
        {
            label => 'UIDNA object',
            define => 'UICU_HAS_UIDNA_OBJECT',
            c => q[
                #include <unicode/uidna.h>
                int main() {
                    void *ptr = (void*) uidna_openUTS46;
                    return 0;
                }
            ],
        },

        {
            label => 'UIDNA_CHECK_CONTEXTO',
            define => 'UICU_HAS_UIDNA_CHECK_CONTEXTO',
            c => q[
                #include <unicode/uidna.h>
                int main() {
                    int foo = UIDNA_CHECK_CONTEXTO;
                    return 0;
                }
            ],
        },

        {
            label => 'MessagePattern',
            define => 'UICU_HAS_MESSAGEPATTERN',
            c => q[
                #include <unicode/messagepattern.h>
                int main() {
                    return 0;
                }
            ],
        },

        {
            label => 'UMSGPAT_ARG_TYPE_SELECTORDINAL',
            define => 'UICU_HAS_UMSGPAT_ARG_TYPE_SELECTORDINAL',
            c => q[
                #include <unicode/messagepattern.h>
                int main() {
                    int foo = UMSGPAT_ARG_TYPE_SELECTORDINAL;
                    return 0;
                }
            ],
        },

        {
            label => 'ListFormatter',
            define => 'UICU_CAN_FORMAT_LISTS',
            c => q[
                #include <unicode/ulistformatter.h>
                int main() {
                    void *p = (void*) ulistfmt_open;
                    return 0;
                }
            ],
        },

        {
            label => 'ListFormatter-or',
            define => 'UICU_CAN_FORMAT_OR',
            c => q[
                #include <unicode/ulistformatter.h>
                int main() {
                    int what = ULISTFMT_TYPE_OR;
                    return 0;
                }
            ],
        },
    );

    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    my $i = 0;

    for my $check_hr (@checks) {
        ++$i;

        _note("Checking: $check_hr->{'label'}");

        my $path = "$dir/source-$i.cc";
        open my $fh, '>', $path;
        syswrite($fh, $check_hr->{'c'});
        close $fh;

        my $obj_file = eval {
            $builder->compile(
                source => $path,
            );
        };

        my $supported;

        if ($obj_file) {
            my $lib_file = eval {
                $builder->link(
                    objects => $obj_file,
                    extra_linker_flags => $lflags,
                );
            };

            if ($lib_file) {
                $supported = 1;
                push @defines, $check_hr->{'define'};
            }
        }

        my $result = ($supported ? q<> : 'NOT ') . 'supported';
        _note("\t$check_hr->{'label'}: $result");
    }

    return map { "-D$_" } @defines;
}

sub _note {
    print "===== @_$/";
}
