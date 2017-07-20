use strict;
use warnings;
use lib '.';

use t::helper;
use Test::More;

use Text::Xslate;

my $warned = 0;
my $died   = 0;

my %common_args = (
    path         => path,
    cache_dir    => cache_dir,
    warn_handler => sub { $warned += 1 },
    die_handler  => sub { $died   += 1 },
);

subtest 'warn' => sub {
    my $xslate = Text::Xslate->new(
        %common_args,
        module => [
            'Text::Xslate::Bridge::TypeDeclaration' => [
                on_mismatch => 'warn'
            ],
        ],
    );
    $warned = 0;
    $died   = 0;

    my $res;

    $res = $xslate->render('a.tx', { a => 123, b => t::SomeModel->new });
    is $res, "123\n";
    is $warned, 0;
    is $died,   0;

    $res = $xslate->render('a.tx', { a => 123 });
    like $res, qr/Declaration mismatch for `b`/;
    is $warned, 1;
    is $died,   0;

    $res = $xslate->render('a.tx', { a => 'hoge', b => 'fuga' });
    like $res, qr/Declaration mismatch for `a`/;
    like $res, qr/Declaration mismatch for `b`/;
    is $warned, 3;
    is $died,   0;
};

subtest 'die' => sub {
    my $xslate = Text::Xslate->new(
        %common_args,
        module => [
            'Text::Xslate::Bridge::TypeDeclaration' => [
                on_mismatch => 'die',
            ],
        ],
    );
    $warned = 0;
    $died   = 0;

    my $res;

    $res = $xslate->render('a.tx', { a => 123, b => t::SomeModel->new });
    is $res, "123\n";
    is $warned, 0;
    is $died,   0;

    $res = $xslate->render('a.tx', { a => 123 });
    like $res, qr/Declaration mismatch for `b`/;
    is $warned, 0;
    is $died,   1;

    $res = $xslate->render('a.tx', { a => 'hoge', b => 'fuga' });
    like   $res, qr/Declaration mismatch for `a`/;
    unlike $res, qr/Declaration mismatch for `b`/, 'stop validation loop on die';
    is $warned, 0;
    is $died,   2;
};

subtest 'none' => sub {
    my $xslate = Text::Xslate->new(
        %common_args,
        module => [
            'Text::Xslate::Bridge::TypeDeclaration' => [
                on_mismatch => 'none'
            ],
        ],
    );
    $warned = 0;
    $died   = 0;

    my $res;

    $res = $xslate->render('a.tx', { a => 123, b => t::SomeModel->new });
    is $res, "123\n";
    is $warned, 0;
    is $died,   0;

    $res = $xslate->render('a.tx', { a => 123 });
    like $res, qr/Declaration mismatch for `b`/;
    is $warned, 0;
    is $died,   0;

    $res = $xslate->render('a.tx', { a => 'hoge', b => 'fuga' });
    like $res, qr/Declaration mismatch for `a`/;
    like $res, qr/Declaration mismatch for `b`/;
    is $warned, 0;
    is $died,   0;
};

done_testing;

__DATA__
@@ a.tx
<: declare(a => 'Int', b => 't::SomeModel'):><: $a :>
