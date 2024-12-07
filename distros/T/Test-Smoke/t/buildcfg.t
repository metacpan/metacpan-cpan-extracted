#! /usr/bin/perl -w
use strict;

use Test::More;
my $verbose = 0;

my $findbin;
use File::Basename;
use File::Spec::Functions;
BEGIN { $findbin = dirname $0; }
use lib $findbin;
use TestLib;

use_ok "Test::Smoke::BuildCFG";

{ # Start with a basic configuration
    my $dft_cfg = <<__EOCFG__;

-Uuseperlio
=

-Duseithreads
=
/-DDEBUGGING/

-DDEBUGGING
__EOCFG__

    my $dft_sect = [
        [ '', '-Uuseperlio' ],
        [ '', '-Duseithreads' ],
        { policy_target => '-DDEBUGGING', args => [ '', '-DDEBUGGING'] },
    ];

    my $bcfg = Test::Smoke::BuildCFG->new( \$dft_cfg => { v => $verbose } );
    isa_ok $bcfg, "Test::Smoke::BuildCFG";

    is_deeply $bcfg->{_sections}, $dft_sect, "Parse a configuration";

    is $bcfg->as_string, $dft_cfg, "as_string()";
}

{ # Check that order within sections is honored
    my $dft_cfg = <<__EOCFG__;

-Duseithreads
=
-Uuseperlio

-Duse64bitint
=
/-DDEBUGGING/

-DDEBUGGING
__EOCFG__

    my $dft_sect = [
        [ '', '-Duseithreads' ],
        [ '-Uuseperlio', '', '-Duse64bitint' ],
        { policy_target => '-DDEBUGGING', args => [ '', '-DDEBUGGING'] },
    ];

    my $bcfg = Test::Smoke::BuildCFG->new( \$dft_cfg => { v => $verbose } );

    is_deeply $bcfg->{_sections}, $dft_sect, "Section-order kept";

    my $first = ( $bcfg->configurations )[0];
    isa_ok( $first, 'Test::Smoke::BuildCFG::Config');
    is( "$first", $first->[0], "as_string: $first->[0]" );
    foreach my $config ( $bcfg->configurations ) {
        if ( ($config->policy)[0]->[1] ) {
            ok( $config->has_arg( '-DDEBUGGING' ), "has_arg(-DDEBUGGING)" );
            like( "$config", '/-DDEBUGGING/', 
                  "'$config' has -DDEBUGGING" );
        } else {
            ok( !$config->has_arg( '-DDEBUGGING' ), "! has_arg(-DDEBUGGING)" );
            unlike( "$config", '/-DDEBUGGING/', 
                    "'$config' has no -DDEBUGGING" );
        }
        ok( $config->args_eq( "$config" ), "Stringyfied: args_eq($config)" );
    }
    is $bcfg->as_string, $dft_cfg, "as_string()";
}

{ # Check that empty lines at the end of sections are honored
    my $dft_cfg = <<__EOCFG__;
-Duseithreads

=
/-DDEBUGGING/

-DDEBUGGING
__EOCFG__

    my $dft_sect = [
        [ '-Duseithreads', '' ],
        { policy_target => '-DDEBUGGING', args => [ '', '-DDEBUGGING'] },
    ];

    my $bcfg = Test::Smoke::BuildCFG->new( \$dft_cfg => { v => $verbose } );

    is_deeply $bcfg->{_sections}, $dft_sect, 
              "Empty lines at end of section kept";

    my $first = ( $bcfg->configurations )[0];
    isa_ok( $first, 'Test::Smoke::BuildCFG::Config');
    is( "$first", $first->[0], "as_string: $first->[0]" );
    foreach my $config ( $bcfg->configurations ) {
        if ( ($config->policy)[0]->[1] ) {
            ok( $config->has_arg( '-DDEBUGGING' ), "has_arg(-DDEBUGGING)" );
            like( "$config", '/-DDEBUGGING/', 
                  "'$config' has -DDEBUGGING" );
        } else {
            ok( !$config->has_arg( '-DDEBUGGING' ), "! has_arg(-DDEBUGGING)" );
            unlike( "$config", '/-DDEBUGGING/', 
                    "'$config' has no -DDEBUGGING" );
        }
        ok( $config->args_eq( "$config" ), "Stringyfied: args_eq($config)" );
    }
    is $bcfg->as_string, $dft_cfg, "as_string()"
}

{ # Check that empty sections are skipped
    my $dft_cfg = <<__EOCFG__;
# This is an empty section

# It really is, although it's got an empty (non comment) line
=

-Duseithreads
==
-Uuseperlio

-Duse64bitint
=
/-DDEBUGGING/

-DDEBUGGING
__EOCFG__

    my $dft_sect = [
        [ '', '-Duseithreads' ],
        [ '-Uuseperlio', '', '-Duse64bitint' ],
        { policy_target => '-DDEBUGGING', args => [ '', '-DDEBUGGING'] },
    ];

    my $bcfg = Test::Smoke::BuildCFG->new( \$dft_cfg => { v => $verbose } );

    is_deeply $bcfg->{_sections}, $dft_sect, "Empty sections are skipped";

    ( my $as_string = $dft_cfg ) =~ s/^[^=]*=\n//;
    $as_string =~ s/^=.*/=/mg;
    is $bcfg->as_string, $as_string, "as_string()";
}

{ # This is to test the default configuration
    my $dft_sect = [
        [ '', '-Duseithreads'],
        [ '', '-Duse64bitall'],
        { policy_target => '-DDEBUGGING', args => [ '', '-DDEBUGGING'] },
    ];

    my $bcfg = Test::Smoke::BuildCFG->new( undef,  { v => $verbose } );

    is_deeply $bcfg->{_sections}, $dft_sect, "Default configuration"
        or diag(explain($bcfg->{_sections}));
}

{ # Check the new ->policy_targets() method
    my $dft_cfg = <<__EOCFG__;
/-DPERL_COPY_ON_WRITE/

-DPERL_COPY_ON_WRITE
=

-Duseithreads
=
/-DDEBUGGING/

-DDEBUGGING
__EOCFG__

    my $dft_sect = [
        { policy_target => '-DPERL_COPY_ON_WRITE', 
          args          => [ '', '-DPERL_COPY_ON_WRITE'] },
        [ '', '-Duseithreads' ],
        { policy_target => '-DDEBUGGING', args => [ '', '-DDEBUGGING'] },
    ];

    my $bcfg = Test::Smoke::BuildCFG->new( \$dft_cfg => { v => $verbose } );

    is_deeply [ $bcfg->policy_targets ], 
              [qw( -DPERL_COPY_ON_WRITE -DDEBUGGING )],
              "Policy targets...";

    is $bcfg->as_string, $dft_cfg, "as_string()";
}

# Now we need to test the C<continue()> constructor
{
    my $dft_cfg = <<EOCFG;

-Dusethreads
=
/-DDEBUGGING/

-DDEBUGGING
EOCFG

    my $mktest_out = <<OUT;
Smoking patch 20000

Configuration: -Dusedevel
----------------------------------------------------------------------
PERLIO=stdio	All tests successful.

PERLIO=perlio	All tests successful.

Configuration: -Dusedevel -DDEBUGGING
----------------------------------------------------------------------
PERLIO=stdio	All tests successful.

PERLIO=perlio	All tests successful.

Configuration: -Dusedevel -Dusethreads
----------------------------------------------------------------------
PERLIO=stdio	
OUT

    put_file( $mktest_out, 'mktest.out' );
    my $bcfg = Test::Smoke::BuildCFG->continue( 'mktest.out', \$dft_cfg );
    isa_ok( $bcfg, 'Test::Smoke::BuildCFG' );

    my @not_seen;
    push @not_seen, "$_" for $bcfg->configurations;

    is_deeply( \@not_seen, ["-Dusedevel -Dusethreads", 
                            "-Dusedevel -Dusethreads -DDEBUGGING" ],
               "The right configs are left for continue" );
    1 while unlink 'mktest.out';
}

# Test the interface to Test::Smoke::BuildCFG::Config
{
    my $cfgline = q[-Duseithreads -Dcc='gcc'];
    my $bcfg = Test::Smoke::BuildCFG::new_configuration( $cfgline );
    isa_ok $bcfg, 'Test::Smoke::BuildCFG::Config';

    is "$bcfg", $cfgline, "stringify($cfgline)";
    ok $bcfg->has_arg( "-Dcc='gcc'" ),    "has -Dcc='gcc'";
    ok $bcfg->has_arg( "-Duseithreads" ), "has -Duseithreads";
    ok $bcfg->has_arg( "-Dcc='gcc'", "-Duseithreads" ), "has both";
    ok $bcfg->any_arg( "-Dcc='gcc'", "-Duseithreads" ), "has either";
    ok $bcfg->args_eq( $cfgline ), "args_eq()";

    is $bcfg->rm_arg( "-Dcc='gcc'" ), "-Duseithreads", "rm_arg()";
    is "$bcfg", "-Duseithreads", "stringify()";
}

{
    my $bcfg = Test::Smoke::BuildCFG::new_configuration( "" );
    isa_ok $bcfg, "Test::Smoke::BuildCFG::Config";
    is "$bcfg", "", "stringify empty";

    ok !$bcfg->has_arg( '-Duseithreads' ), "hasnt_arg(-Duseithreads)";
}

{
    my $cfg = q/-Dusedevel -Dprefix="sys$login:[perl59x]"/;
    my $bcfg = Test::Smoke::BuildCFG::new_configuration( $cfg );
    isa_ok $bcfg, 'Test::Smoke::BuildCFG::Config';

    is $bcfg->vms,
       q/-"Dusedevel" -"Dprefix=sys$login:[perl59x]"/,
       "check vms cmdline";
}

{
    my %map = (
        MSWin32 => 'w32current.cfg',
        VMS     => 'vmsperl.cfg',
        darwin  => 'perlcurrent.cfg',
        linux   => 'perlcurrent.cfg',
        openbsd => 'perlcurrent.cfg',
    );

    my $base_dir = dirname($INC{'Test/Smoke/BuildCFG.pm'});
    for my $os (sort keys %map) {
        my $config = catfile($base_dir, $map{$os});
        open(my $fh, '<', $config) or die "Cannot open($config): $!";
        my $from_file = do { local $/; <$fh> };
        close($fh);
        my $from_module = Test::Smoke::BuildCFG->os_default_buildcfg($os);
        is($from_module, $from_file, "os_default_buildcfg($os)");
    }
}

done_testing();

package Test::BCFGTester;
use strict;

use Test::Builder;
use base 'Exporter';

use vars qw( $VERSION @EXPORT );
$VERSION = '0.001';
@EXPORT = qw( &config_ok );
