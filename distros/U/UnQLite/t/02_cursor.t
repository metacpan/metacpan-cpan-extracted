use strict;
use Test::More;

use File::Temp qw(tempdir);
use UnQLite;

my $tmp = tempdir( CLEANUP => 1 );

my $db = UnQLite->open("$tmp/foo.db");
{
    isa_ok($db, 'UnQLite');

    ok($db->kv_store("foo", "bar"));
    ok($db->kv_store("hoge", "fuga"));
}

{
    my $cursor = $db->cursor_init();
    $cursor->first_entry;
    is($cursor->valid_entry(), 1);
    is($cursor->key(), 'hoge');
    is($cursor->data(), 'fuga');
    ok($cursor->next_entry());
    is($cursor->valid_entry(), 1);
    is($cursor->key(), 'foo');
    is($cursor->data(), 'bar');
    ok(!$cursor->next_entry());
    is($cursor->valid_entry(), 0);
}

{
    my $cursor = $db->cursor_init();
    my @ret;
    for ($cursor->first_entry; $cursor->valid_entry; $cursor->next_entry) {
        push @ret, $cursor->key(), $cursor->data()
    }
    is_deeply(\@ret, [qw(hoge fuga foo bar)]);
}

{
    my $cursor = $db->cursor_init();
    $cursor->last_entry;
    is($cursor->valid_entry(), 1);
    is($cursor->key(), 'foo');
    is($cursor->data(), 'bar');
    ok($cursor->prev_entry());
    is($cursor->valid_entry(), 1);
    is($cursor->key(), 'hoge');
    is($cursor->data(), 'fuga');
    ok(!$cursor->prev_entry());
    is($cursor->valid_entry(), 0);
}

{
    my $cursor = $db->cursor_init();
    ok(!$cursor->seek("NON EXISTENT"));
    ok($cursor->seek("foo"));
    is($cursor->valid_entry(), 1);
    $cursor->delete_entry();
}

done_testing;

