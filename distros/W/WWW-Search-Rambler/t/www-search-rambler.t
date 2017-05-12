#! /usr/bin/perl
#

use Test::More tests => 4;

BEGIN {
    use_ok ("WWW::Search");
    use_ok ("WWW::Search::Rambler");
};

our $VERSION = (qw$Revision: 1.1 $)[1];

my $ss = new WWW::Search ("Rambler",'charset' => "koi8-r");
$ss->env_proxy (1);
$ss->{'charset'} = "koi8-r";
# $ss->{'_debug'} = 5;

isa_ok ($ss,"WWW::Search");

$ss->native_query ("Артур Пенттинен");

my $cnt = 0;
while (my $r = $ss->next_result ()) {
    $cnt++;
    #diag (sprintf "%02d: %s: %s\n",$cnt,$r->title (),$r->url ());
}

ok ($cnt > 9,"number of results $cnt: " . $ss->approximate_result_count ());

exit;

# That's all, folks!
