use strict;
use Test::More;

use File::Temp qw(tempdir);
use UnQLite;

my $tmp = tempdir( CLEANUP => 1 );

{
    my $db = UnQLite->open("$tmp/foo.db");
    isa_ok($db, 'UnQLite');

    ok($db->kv_store("foo", "bar"));
    is($db->kv_fetch('foo'), 'bar');
    ok($db->kv_delete('foo'));
    is($db->kv_fetch('foo'), undef);
    $db->kv_store('yay', 'yap');
    $db->kv_append('yay', 'po');
    is($db->kv_fetch('yay'), 'yappo');
    is($db->rc,0);
}

{
    ok -e "$tmp/foo.db", "foo.db exists";
    tie my %hash, 'UnQLite', "$tmp/foo.db";

    # stored data can be retrieved again?
    is($hash{yay}, 'yappo');
    $hash{foo} = 'baz';
    is($hash{foo}, 'baz');
    $hash{delete} = 'delete';
    is(delete $hash{delete}, 'delete');
    is(delete $hash{delete}, undef);
    ok(exists $hash{foo});
    ok(!exists $hash{delete});

    is(join(" ", sort keys %hash), "foo yay");
    is(join(" ", sort values %hash), "baz yappo");
    is(scalar %hash, 2);
    %hash = ();
    is(join(" ", sort keys %hash), "");
    is(join(" ", sort values %hash), "");
    is(scalar %hash, undef);
}

done_testing;
