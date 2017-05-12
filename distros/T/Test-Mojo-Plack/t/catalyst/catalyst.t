use Test::More;

use strict;
use warnings;

use utf8;
use Encode;

use Test::Mojo::Plack;
use Mojo::JSON;

use Data::Dumper;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, 'MyApp', 'lib');

plan( skip_all => 'Tests need Catalyst installed to run' ) unless eval { require Catalyst; };

my $t1 = Test::Mojo::Plack->new('MyApp');

$t1->get_ok("/")->status_is(200);

my $json = '{"foo":1}';
$t1->post_ok("/" => {} => json => Mojo::JSON::decode_json($json) );

is($t1->tx->res->body, $json, 'JSON comes back correctly');

$t1->post_ok("/" => {} => json => { foo => "←↓→" } );

is_deeply($t1->tx->res->json, { foo => "←↓→" }, 'JSON comes back correctly');

my $json3 = '{"fooæøå":1}';
$t1->post_ok("/" => {} => json => Mojo::JSON::decode_json(encode_utf8($json3)) );


plan( skip_all => 'Tests need Catalyst installed to run' ) unless eval { require Catalyst::View::JSON; };

is_deeply($t1->tx->res->json, Mojo::JSON::decode_json(encode_utf8($json3)), 'JSON comes back correctly');

$t1->get_ok('/utf8')->json_is('/foo', "–");

done_testing;
