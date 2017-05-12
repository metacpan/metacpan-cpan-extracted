# vim: set sw=4 ts=4 tw=78 et si filetype=perl:

use Test::More;
use WebService::Leanpub;

my ($wl);

eval {
    $wl = WebService::Leanpub->new();
};
like($@, qr/^Missing API key for Leanpub at/, 'new() needs API key');

eval {
    $wl = WebService::Leanpub->new('somekey');
};
like($@, qr/^Missing SLUG for book at/, 'new() needs SLUG for book');

$wl = WebService::Leanpub->new('somekey','books-slug');

done_testing();
