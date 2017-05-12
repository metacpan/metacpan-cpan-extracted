use WWW::Bookmark::Crawler;
$|++;

use Cwd;
use Test;

BEGIN { plan tests => 1 };

$crawler = WWW::Bookmark::Crawler->new({DBNAME => getcwd.'/t/mybookmark.db'});
ok($crawler->query("internet ")?1:0,1);
