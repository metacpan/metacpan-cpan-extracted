use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Local::MockUA;
use Webservice::Overleaf::API;

my $ua = Local::MockUA->new;
$ua->enqueue({
    success => 0,
    status  => 401,
    reason  => 'Unauthorized',
    headers => {},
    content => 'login',
});

my $ol = Webservice::Overleaf::API->new(
    ua           => $ua,
    experimental => 1,
    session      => 'expired',
);

my $ok = eval { $ol->projects; 1 };
ok !$ok, '401 throws';
like $@, qr/authentication failed.*session may have expired/i, '401 classified as auth failure';

$ua->enqueue({
    success => 0,
    status  => 500,
    reason  => 'Internal Server Error',
    headers => {},
    content => 'oops',
});

$ok = eval { $ol->project_zip('p1'); 1 };
ok !$ok, '500 throws';
like $@, qr/HTTP 500 Internal Server Error/, '500 classified as generic HTTP failure';

done_testing;
