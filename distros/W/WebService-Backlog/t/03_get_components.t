use strict;
use Test::More tests => 10;

use WebService::Backlog;
use Encode;

my $backlog = WebService::Backlog->new(
    space    => 'backlog',
    username => 'guest',
    password => 'guest',
);

my $components = $backlog->getComponents(20);
ok($components);
is( scalar( @{$components} ), 4 );
is( $components->[0]->id,     52 );
is( $components->[0]->name,   decode_utf8('ホームページ') );

is( $components->[1]->id,   53 );
is( $components->[1]->name, decode_utf8('アプリ') );

is( $components->[2]->id,   54 );
is( $components->[2]->name, decode_utf8('インフラ・運用') );

is( $components->[3]->id,   2967 );
is( $components->[3]->name, decode_utf8('wiki') );
