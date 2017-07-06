use strict;
use warnings;
use lib '.';

use t::helper;
use Test::More;

use Text::Xslate;
use Text::Xslate::Bridge::TypeDeclaration;

subtest 'import' => sub {
    my $xslate = Text::Xslate->new(
        path      => path,
        cache_dir => cache_dir,
        module => [
            'Text::Xslate::Bridge::TypeDeclaration' => [ validate => 0 ]
        ],
    );

    is $xslate->render('a.tx', {}), "\n";
    is $xslate->render('a.tx', { a => 'hoge' }), "hoge\n";
};

subtest 'disable flag' => sub {
    my $xslate = Text::Xslate->new(
        path         => path,
        cache_dir    => cache_dir,
        warn_handler => sub {},
        module => [
            'Text::Xslate::Bridge::TypeDeclaration' => [ validate => 1 ]
        ],
    );

    my $res;
    $res = $xslate->render('a.tx', { a => 'hoge' });
    like $res, qr/Declaration mismatch/;
    like $res, qr/hoge\n\z/;

    local $Text::Xslate::Bridge::TypeDeclaration::DISABLE_VALIDATION = 1;

    $res = $xslate->render('a.tx', { a => 'hoge' });
    unlike $res, qr/Declaration mismatch/;
    is $res, "hoge\n";
};

done_testing;

__DATA__
@@ a.tx
<: declare(a => 'Int'):><: $a :>
