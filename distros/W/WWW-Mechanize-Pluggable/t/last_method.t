use Test::More tests=>2;
use FindBin;
use lib "$FindBin::Bin/lib";

use WWW::Mechanize::Pluggable;
my $m = WWW::Mechanize::Pluggable->new;
$m->res;
is $m->last_method(), 'res', 'last_method works for instance methods';
WWW::Mechanize::Pluggable->classy;
is $m->last_method(), 'res', 'last_method unchanged for class methods';
