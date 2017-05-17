#! perl -w
use strict;

use Test::More;
plan skip_all => "This ($^O) is not MSWin32!" if $^O ne 'MSWin32';

require Win32::API;
require Test::Smoke::Util::Win32ErrorMode;

my %flags = (
    SEM_FAILCRITICALERRORS     => 0x0001,
    SEM_NOGPFAULTERRORBOX      => 0x0002,
    SEM_NOALIGNMENTFAULTEXCEPT => 0x0004,
    SEM_NOOPENFILEERRORBOX     => 0x0008,
);

{
    # These settings work for the process (ie. this test)
    Test::Smoke::Util::Win32ErrorMode::lower_error_settings();

    my $get_error_mode = Win32::API->new('kernel32', 'GetErrorMode', 'V', 'I');
    my $mode = $get_error_mode->Call();

    is(
        $mode & $flags{SEM_FAILCRITICALERRORS},
        $flags{SEM_FAILCRITICALERRORS},
        "mode contains 'SEM_FAILCRITICALERRORS'"
    );
    is(
        $mode & $flags{SEM_NOGPFAULTERRORBOX},
        $flags{SEM_NOGPFAULTERRORBOX},
        "mode contains 'SEM_NOGPFAULTERRORBOX'"
    );
    is(
        $mode & $flags{SEM_NOALIGNMENTFAULTEXCEPT},
        0,
        "mode does not contain 'SEM_NOALIGNMENTFAULTEXCEPT'"
    );
    is(
        $mode & $flags{SEM_NOOPENFILEERRORBOX},
        0,
        "mode does not contain 'SEM_NOOPENFILEERRORBOX'"
    );
}

done_testing();
