use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

my $fixture_boot           = load_fixture('robot_boot_get');
my $fixture_rescue         = load_fixture('robot_boot_rescue');
my $fixture_rescue_active  = load_fixture('robot_boot_rescue_active');
my $fixture_linux          = load_fixture('robot_boot_linux');
my $fixture_linux_active   = load_fixture('robot_boot_linux_active');
my $fixture_vnc            = load_fixture('robot_boot_vnc');
my $fixture_vnc_active     = load_fixture('robot_boot_vnc_active');
my $fixture_windows        = load_fixture('robot_boot_windows');
my $fixture_windows_active = load_fixture('robot_boot_windows_active');

# what the activating POSTs actually put on the wire
my %sent;

my $robot = mock_robot(
    'GET /boot/123456'            => $fixture_boot,

    'GET /boot/123456/rescue'     => $fixture_rescue,
    'POST /boot/123456/rescue'    => sub {
        my ($method, $path, %opts) = @_;
        $sent{rescue} = $opts{body};
        return $fixture_rescue_active;
    },
    'DELETE /boot/123456/rescue'  => $fixture_rescue,

    'GET /boot/123456/linux'      => $fixture_linux,
    'POST /boot/123456/linux'     => sub {
        my ($method, $path, %opts) = @_;
        $sent{linux} = $opts{body};
        return $fixture_linux_active;
    },
    'DELETE /boot/123456/linux'   => $fixture_linux,

    'GET /boot/123456/vnc'        => $fixture_vnc,
    'POST /boot/123456/vnc'       => sub {
        my ($method, $path, %opts) = @_;
        $sent{vnc} = $opts{body};
        return $fixture_vnc_active;
    },
    'DELETE /boot/123456/vnc'     => $fixture_vnc,

    'GET /boot/123456/windows'    => $fixture_windows,
    'POST /boot/123456/windows'   => sub {
        my ($method, $path, %opts) = @_;
        $sent{windows} = $opts{body};
        return $fixture_windows_active;
    },
    'DELETE /boot/123456/windows' => $fixture_windows,
);

subtest 'get boot status of all options' => sub {
    my $boot = $robot->boot->get(123456);
    is(ref($boot), 'HASH', 'unwrapped from the boot envelope');
    is_deeply([sort keys %$boot], [qw(linux rescue vnc windows)], 'all four boot options');
    is($boot->{rescue}{server_number}, 123456, 'rescue server_number');
    ok(!$boot->{rescue}{active}, 'rescue inactive');
    is_deeply($boot->{linux}{lang}, ['en'], 'linux languages listed');
};

subtest 'rescue system' => sub {
    my $rescue = $robot->boot->rescue(123456);
    is_deeply($rescue->{os}, ['linux', 'vkvm'], 'available rescue systems');
    ok(!$rescue->{active}, 'inactive');
    is($rescue->{password}, undef, 'no password while inactive');

    my $active = $robot->boot->enable_rescue(123456,
        os             => 'linux',
        authorized_key => ['aa:bb:cc:dd'],
        keyboard       => 'de',
    );
    ok($active->{active}, 'active after enable');
    is($active->{os}, 'linux', 'booted os');
    is($active->{password}, 'jEt0dtUvomlyOwRr', 'generated root password returned');

    is_deeply($sent{rescue}, {
        os             => 'linux',
        authorized_key => ['aa:bb:cc:dd'],
        keyboard       => 'de',
    }, 'os, authorized_key and keyboard sent');

    my $off = $robot->boot->disable_rescue(123456);
    ok(!$off->{active}, 'inactive after disable');
};

subtest 'rescue: optional params are omitted, not sent as undef' => sub {
    delete $sent{rescue};
    $robot->boot->enable_rescue(123456, os => 'vkvm');
    is_deeply($sent{rescue}, { os => 'vkvm' }, 'only os sent');
};

subtest 'linux installation' => sub {
    my $linux = $robot->boot->linux(123456);
    is_deeply($linux->{lang}, ['en'], 'available languages');
    ok(!$linux->{active}, 'inactive');

    my $active = $robot->boot->enable_linux(123456,
        dist => 'Debian 12 minimal',
        lang => 'en',
    );
    ok($active->{active}, 'active after enable');
    is($active->{dist}, 'Debian 12 minimal', 'installed dist');
    is($active->{password}, 'hRk9pQ2xLmNvBzTa', 'generated root password returned');
    is_deeply($sent{linux}, { dist => 'Debian 12 minimal', lang => 'en' }, 'dist and lang sent');

    my $off = $robot->boot->disable_linux(123456);
    ok(!$off->{active}, 'inactive after disable');
};

subtest 'vnc installation' => sub {
    my $vnc = $robot->boot->vnc(123456);
    ok(!$vnc->{active}, 'inactive');

    my $active = $robot->boot->enable_vnc(123456, dist => 'centOS-5.0', lang => 'en_US');
    ok($active->{active}, 'active after enable');
    is($active->{password}, 'zQw3RtYuIoPaSdFg', 'generated password returned');
    is_deeply($sent{vnc}, { dist => 'centOS-5.0', lang => 'en_US' }, 'dist and lang sent');

    my $off = $robot->boot->disable_vnc(123456);
    ok(!$off->{active}, 'inactive after disable');
};

subtest 'windows installation' => sub {
    my $windows = $robot->boot->windows(123456);
    ok(!$windows->{active}, 'inactive');

    my $active = $robot->boot->enable_windows(123456,
        os   => 'Windows Server 2022 Standard Edition',
        lang => 'en',
    );
    ok($active->{active}, 'active after enable');
    is($active->{password}, 'mNbVcXzLkJhGfDsA', 'generated password returned');
    is_deeply($sent{windows}, {
        os   => 'Windows Server 2022 Standard Edition',
        lang => 'en',
    }, 'os and lang sent');

    my $off = $robot->boot->disable_windows(123456);
    ok(!$off->{active}, 'inactive after disable');
};

subtest 'required parameters are enforced before any request' => sub {
    like(exception(sub { $robot->boot->get() }),
        qr/Server number required/, 'get without server number');
    like(exception(sub { $robot->boot->rescue() }),
        qr/Server number required/, 'rescue without server number');
    like(exception(sub { $robot->boot->enable_rescue(123456) }),
        qr/os required/, 'enable_rescue without os');
    like(exception(sub { $robot->boot->enable_linux(123456, lang => 'en') }),
        qr/dist required/, 'enable_linux without dist');
    like(exception(sub { $robot->boot->enable_linux(123456, dist => 'Debian 12 minimal') }),
        qr/lang required/, 'enable_linux without lang');
    like(exception(sub { $robot->boot->enable_vnc(123456, lang => 'en_US') }),
        qr/dist required/, 'enable_vnc without dist');
    like(exception(sub { $robot->boot->enable_windows(123456, lang => 'en') }),
        qr/os required/, 'enable_windows without os');
};

sub exception {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : $@;
}

done_testing;
