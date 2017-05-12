#! /usr/bin/perl
#

use blib;

use Test::More tests => 4;
use Encode qw( decode );

BEGIN {
    use_ok ("WWW::Search");
    use_ok ("WWW::Search::Yandex")
};

my $srch = new WWW::Search ("Yandex");
$srch->env_proxy ("yes");

isa_ok ($srch,"WWW::Search");
# $srch->{'_debug'} = 10;

my $query = decode("koi8-r", "use perl or die");
$srch->native_query($query);

my $cnt = 0;
while (my $res = $srch->next_result ()) {
    diag(sprintf "%2d: %s", ++$cnt, $res->url());
}

ok ($cnt > 9,"results count: $cnt");

exit;

# That's all, folks!
