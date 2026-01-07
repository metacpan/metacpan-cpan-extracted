use v5.14;
use warnings;

use UV::Loop ();
use UV::Process ();

use Test::More;

plan skip_all => "Not supported on MSWin32" if $^O eq "MSWin32";
plan skip_all => "Not running as root" unless $< == 0;

{
    my $exit_status;

    my $process = UV::Process->spawn(
        file => $^X,
        setuid => 10,
        args => [ "-e", 'exit ($< == 10)' ],
        on_exit => sub {
            (undef, $exit_status, undef) = @_;
        },
    );

    UV::Loop->default()->run();

    is($exit_status, 1, 'exit status from perl setuid`');
}

done_testing();
