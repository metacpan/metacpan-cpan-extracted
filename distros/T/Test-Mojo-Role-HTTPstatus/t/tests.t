use Test::More;

use Mojolicious::Lite;

use Test::Mojo::WithRoles qw(HTTPstatus);

any '/' => {text => 'Hello Test!'};

my $t = Test::Mojo::WithRoles->new;

subtest "make sure we didn't break Test::Mojo" => sub {
    $t->get_ok('/')->status_is(200)->content_is('Hello Test!');
};

subtest "end to end test" => sub {
    $t->get_ok('/')->status_is_success();
};

my @args;
$t->handler(sub { @args = @_ });

subtest 'status_like' => sub {
    $t->status_like(qr/^2/);
    is_deeply \@args, ['like', 200, qr/^2/, '200 like '.qr/^2/], 'right result';
    $t->status_like(qr/^2/, 'some description');
    is_deeply \@args, ['like', 200, qr/^2/, 'some description'], 'right result';
};

subtest 'status_unlike' => sub {
    $t->status_unlike(qr/^2/);
    is_deeply \@args, ['unlike', 200, qr/^2/, '200 unlike '.qr/^2/], 'right result';
    $t->status_unlike(qr/^2/, 'some description');
    is_deeply \@args, ['unlike', 200, qr/^2/, 'some description'], 'right result';
};

subtest 'status_is_client_error internals' => sub {
    $t->status_is_client_error();
    is_deeply \@args, ['like', 200, qr/^4\d\d$/a, '200 is client error'], 'right result';
};

subtest 'status_is_empty internals' => sub {
    $t->status_is_empty();
    is_deeply \@args, ['like', 200, qr/^(1\d\d|[23]04)$/a, '200 is empty'], 'right result';
};

subtest 'status_is_error internals' => sub {
    $t->status_is_error();
    is_deeply \@args, ['like', 200, qr/^[45]\d\d$/a, '200 is error'], 'right result';
};

subtest 'status_is_info internals' => sub {
    $t->status_is_info();
    is_deeply \@args, ['like', 200, qr/^1\d\d$/a, '200 is info'], 'right result';
};

subtest 'status_is_redirect internals' => sub {
    $t->status_is_redirect();
    is_deeply \@args, ['like', 200, qr/^3\d\d$/a, '200 is redirect'], 'right result';
};

subtest 'status_is_server_error internals' => sub {
    $t->status_is_server_error();
    is_deeply \@args, ['like', 200, qr/^5\d\d$/a, '200 is server error'], 'right result';
};

subtest 'status_is_success internals' => sub {
    $t->status_is_success();
    is_deeply \@args, ['like', 200, qr/^2\d\d$/a, '200 is success'], 'right result';
};

done_testing();
