use strict;
use warnings;

use IO::Socket::INET;
use POSIX qw(SIGHUP);
use Test::More;
use UV ();
use UV::Loop ();

sub _cleanup_loop {
    my $loop = shift;
    $loop->walk(sub {shift->close()});
    $loop->run(UV::Loop::UV_RUN_DEFAULT);
}

{
    my $time = UV::hrtime();
    ok($time, "hrtime: got back - $time");
    ok(UV::hrtime(), "hrtime - no assignment");
    diag("Using v".UV::version_string());
    ok(UV::version_string(), 'got a version string');
    ok(UV::version(), 'got a version hex');
    is(UV::strerror(UV::UV_ENOSYS), 'function not implemented', 'Got the right constant value');
    is(UV::err_name(UV::UV_ENOSYS), 'ENOSYS', 'Got the right constant name');
}

{
    my $loop = UV::loop();
    isa_ok($loop, 'UV::Loop', 'got back the loop');
    is($loop->is_default(), 1, 'is the default loop');
    my $loop2 = UV::loop();
    isa_ok($loop2, 'UV::Loop', 'got back the loop');
    is($loop2->is_default(), 1, 'is the default loop');
    is($loop, $loop2, 'They are the same loop');
}

{
    my $handle = UV::check();
    isa_ok($handle, 'UV::Check', 'got back a Check handle');
    isa_ok($handle, 'UV::Handle', 'it derives from UV::Handle');
    is($handle->loop()->is_default(), 1, 'Handle uses the default loop');
    _cleanup_loop(UV::Loop->default());
}

{
    my $handle = UV::idle();
    isa_ok($handle, 'UV::Idle', 'got back an Idle handle');
    isa_ok($handle, 'UV::Handle', 'it derives from UV::Handle');
    is($handle->loop()->is_default(), 1, 'Handle uses the default loop');
    _cleanup_loop(UV::Loop->default());
}

{
    # use a socket since windows can't poll on file descriptors
    my $sock = IO::Socket::INET->new(Type => SOCK_STREAM);
    my $handle = UV::poll(socket => $sock);
    isa_ok($handle, 'UV::Poll', 'got back an Poll handle');
    isa_ok($handle, 'UV::Handle', 'it derives from UV::Handle');
    is($handle->loop()->is_default(), 1, 'Handle uses the default loop');
    _cleanup_loop(UV::Loop->default());
}

{
    my $handle = UV::prepare();
    isa_ok($handle, 'UV::Prepare', 'got back an Prepare handle');
    isa_ok($handle, 'UV::Handle', 'it derives from UV::Handle');
    is($handle->loop()->is_default(), 1, 'Handle uses the default loop');
    _cleanup_loop(UV::Loop->default());
}

{
    my $handle = UV::signal(signal => SIGHUP);
    isa_ok($handle, 'UV::Signal', 'got back a Signal handle');
    isa_ok($handle, 'UV::Handle', 'it derives from UV::Handle');
    is($handle->loop()->is_default(), 1, 'Signal uses the default loop');
    _cleanup_loop(UV::Loop->default());
}

{
    my $handle = UV::timer();
    isa_ok($handle, 'UV::Timer', 'got back an Timer handle');
    isa_ok($handle, 'UV::Handle', 'it derives from UV::Handle');
    is($handle->loop()->is_default(), 1, 'Handle uses the default loop');
    _cleanup_loop(UV::Loop->default());
}

done_testing();
