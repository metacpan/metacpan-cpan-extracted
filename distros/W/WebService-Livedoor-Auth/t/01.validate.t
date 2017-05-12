use Test::More tests => 4;

use WebService::Livedoor::Auth;

{
    my $auth = eval {
        WebService::Livedoor::Auth->new;
    };
    ok(!$auth);
    like($@, qr/Mandatory/);
}

{
    my $auth = eval {
        WebService::Livedoor::Auth->new({
            app_key => 'ac68fa32da1305dafe3421d012f0aaba',
            secret => 'ccd0ea2d35d7bafd',
        });
    };
    ok($auth);
    is($auth->app_key, 'ac68fa32da1305dafe3421d012f0aaba');
}

