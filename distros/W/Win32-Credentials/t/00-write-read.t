use strict;
use warnings;
use Test::More;

# Skip non-Windows
plan skip_all => 'Windows only' unless $^O eq 'MSWin32';

use_ok('Win32::Credentials', qw(cred_write cred_read cred_delete));

my $target = 'Win32-Credentials-test-' . $$;  # PID uniqueness
my $user   = 'testuser';
my $secret = 'test_secret_' . 'x' x 20;

# Write
ok( eval { cred_write($target, $user, $secret); 1 },
    'cred_write succeeded' );

# Read scalar
my $got = cred_read($target);
is($got, $secret, 'cred_read returns correct secret');

# Read list
my ($got2, $got_user) = cred_read($target);
is($got2,     $secret, 'cred_read list: secret ok');
is($got_user, $user,   'cred_read list: username ok');

# Delete
ok( eval { cred_delete($target); 1 }, 'cred_delete succeeded' );

# Verify deleted
eval { cred_read($target) };
like($@, qr/1168/, 'reading deleted credential fails with 1168');

done_testing();