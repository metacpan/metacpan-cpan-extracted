use 5.008000;

use strict;
use warnings;

use ExtUtils::MakeMaker;

our (%CONFIGURE_REQUIRES, %TEST_REQUIRES, %PREREQ_PM);
BEGIN {
    %CONFIGURE_REQUIRES= (
        'Devel::CheckLib'     => '1.03',
        'ExtUtils::Depends'   => '0.405',
        'ExtUtils::MakeMaker' => 0,
    );
    %TEST_REQUIRES= (
        'Test::More'   => 0,
    );
    %PREREQ_PM= (
        'Try::Tiny'    => 0,
        'Carp'         => 0,
        'Scalar::Util' => 0,
        'strict'       => 0,
        'warnings'     => 0,
    );

    # If the prereqs for this script are missing,
    # write out a Makefile that tells CPAN to install them
    my $use_prereqs_code= join('', map { "use $_ '$CONFIGURE_REQUIRES{$_}'; " } keys %CONFIGURE_REQUIRES).'1;';
    print $use_prereqs_code."\n";
    unless (eval $use_prereqs_code) {
       warn "$@\n";
       WriteMakefile(
             NAME         => 'X11::Xlib',
             PREREQ_FATAL => 1,
             PREREQ_PM    => \%CONFIGURE_REQUIRES,
       );
       exit 1; # not reached
    }
}

my $dep= ExtUtils::Depends->new('X11::Xlib');

# TODO: follow the pattern of Glib perl module and detect which extensions are
#   present, then use that to determine which headers to include and which XS
#   files to merge together.

check_lib_or_exit(
    lib    => 'X11',
    header => [ 'X11/Xlib.h', 'X11/Xutil.h' ]
);

check_lib_or_exit(
    lib    => 'Xtst',
    header => [ 'X11/extensions/XTest.h' ]
);

check_lib_or_exit(
    lib    => 'Xext'
);

my @libs= qw( X11 Xtst Xext );
my @have;
sub add_optional_lib {
    my ($lib, $header)= @_;
    warn "Checking for extension $lib\n";
    if (check_lib( lib => $lib, header => (ref $header? $header : [ $header ]) )) {
        warn "  found!\n";
        push @libs, $lib;
        push @have, uc($lib);
    } else {
        warn "  not available.\n";
    }
}

add_optional_lib( Xcomposite => 'X11/extensions/Xcomposite.h' );
add_optional_lib( Xfixes     => 'X11/extensions/Xfixes.h' );

$dep->set_libs(join(' ', map { "-l$_" } @libs));
$dep->add_c('PerlXlib.c');
$dep->add_xs('Xlib.xs');
$dep->add_pm(map { my $n= $_; $n =~ s/^lib/\$(INST_LIB)/; $_ => $n } <lib/*/*.pm>, <lib/*/*/*.pm>);
$dep->add_typemaps('typemap');
$dep->install('PerlXlib.h');

mkdir 'build', 0777;
$dep->save_config('build/IFiles.pm');

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %WriteMakefileArgs = (
    NAME         => 'X11::Xlib',
    VERSION_FROM => 'lib/X11/Xlib.pm',    # finds $VERSION
    ($] >= 5.005 ?                        ## Add these new keywords supported since 5.005
          (ABSTRACT_FROM => 'lib/X11/Xlib.pm',    # retrieve abstract from module
            AUTHOR => [
              'Olivier Thauvin <nanardon@nanardon.zarb.org>',
              'Michael Conrad <mike@nrdvana.net>'
            ]) : ()),
    
    # Split out or combine dependencies depending on version of MakeMaker
    ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ? (
        CONFIGURE_REQUIRES => \%CONFIGURE_REQUIRES,
        TEST_REQUIRES      => \%TEST_REQUIRES,
        PREREQ_PM          => \%PREREQ_PM,
    ) : eval { ExtUtils::MakeMaker->VERSION(6.52) } ? (
        CONFIGURE_REQUIRES => \%CONFIGURE_REQUIRES,
        PREREQ_PM          => { %PREREQ_PM, %TEST_REQUIRES },
    ) : (
        PREREQ_PM          => { %PREREQ_PM, %TEST_REQUIRES, %CONFIGURE_REQUIRES },
    )),
    DEFINE => join(' ', (map { "-DHAVE_$_" } @have)),
    
    META_MERGE => {
        resources => {
            bugtracker => 'https://github.com/nanardon/X11-Xlib/issues',
            repository => 'https://github.com/nanardon/X11-Xlib.git',
        }
    },
    
    $dep->get_makefile_vars,
);

WriteMakefile( %WriteMakefileArgs );
