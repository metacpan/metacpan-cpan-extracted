use utf8;
use Test::More tests => 4;
use Test::Exception;

use_ok('WebService::Booklog');

my ($obj, $dat);
lives_ok { $obj = WebService::Booklog->new; } 'new';

lives_ok { $dat = $obj->get_review(60694202); } 'get';
like $dat, qr/ソフトウェア・アーキテクトによる97\+11本のエッセイ集。/, 'content';
