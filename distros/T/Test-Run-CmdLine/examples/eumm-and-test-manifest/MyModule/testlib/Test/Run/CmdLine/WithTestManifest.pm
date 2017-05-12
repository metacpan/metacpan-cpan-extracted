package Test::Run::CmdLine::WithTestManifest;

use strict;
use warnings;

use File::Spec;

use Test::Manifest ();

use Test::Run::CmdLine::Iface;

sub run_t_manifest
{
    my ($test_verbose, $inst_lib, $inst_archlib, $test_level) = @_;
    local @INC = @INC;
    unshift @INC, map { File::Spec->rel2abs($_) } ($inst_lib, $inst_archlib);

    my $test_iface = Test::Run::CmdLine::Iface->new({
            test_files => [Test::Manifest::get_t_files()]
        }
    );

    return $test_iface->run();
}

1;
