#! perl -w
use strict;

# $Id$

use File::Spec;

use Test::More tests => 9;
BEGIN { use_ok( 'Test::Smoke::Util' ); }

# This test creates files in the current directory,
# it seems better to do it in the "t/" directory
chdir 't' or die "chdir: $!" if -d 't';

my $cfg_name = 'test.cfg';

is( get_cfg_filename(), undef, "Return undef for no args" );
is( get_cfg_filename( 'willnotexists' ), undef,
    "Return undef for unknown" );
my $acfg = '../lib/Test/Smoke/perlcurrent.cfg';
is( get_cfg_filename( $acfg ), $acfg, "Confirm existance ($acfg)" );

SKIP: {
    write_cfg_file( $cfg_name ) or skip "Can't create '$cfg_name'", 2;
    pass( "Create local config file" );
    my $get_cfg = get_cfg_filename( $cfg_name );

    is( $get_cfg, $cfg_name, "get_cfg_name()" );
}

my $df_cfg = [
        [ "",
          "-Dusethreads -Duseithreads"
        ],
        [ "",
          "-Duse64bitint",
          "-Duse64bitall",
          "-Duselongdouble",
          "-Dusemorebits",
          "-Duse64bitall -Duselongdouble"
        ],
        { policy_target =>       "-DDEBUGGING",
          args          => [ "", "-DDEBUGGING" ]
        },
];

{
    my @config = get_config();
    is_deeply( \@config, $df_cfg, "Return default configuration" );
}

SKIP: {
    my $get_cfg = get_cfg_filename( $cfg_name );
    my @config = get_config( $get_cfg );

    is_deeply( \@config, [ ["", "-Dusemymalloc"], ["", "-Dusethreads"],
                           {args => ["", "-DDEBUGGING"],
                            policy_target => '-DDEBUGGING'} ],
               "Parse test configuration" );

    ok( unlink( $get_cfg ), "Clean-up" ) 
        or diag "$get_cfg: $!";
}

END {
    chdir File::Spec->updir
        if -d File::Spec->catdir( File::Spec->updir, 't' );
}

sub write_cfg_file {
    my( $name, $cfg ) = @_;
    $cfg ||= <<EO_CFG;
# empty section

=
# empty line for perlio

-Dusemymalloc
=

-Dusethreads
=
/-DDEBUGGING/

-DDEBUGGING
EO_CFG

    local *CFG;
    open CFG, "> $name" or return;
    print CFG $cfg;
    close CFG or return;
    1;
}
