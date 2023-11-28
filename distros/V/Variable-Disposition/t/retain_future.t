use strict;
use warnings;

use Test::More;
use Test::Refcount;
use Variable::Disposition qw(retain_future dispose);

unless(eval { require Future }) {
    plan skip_all => 'this test requires Future.pm';
}

for my $resolution (qw(done fail cancel)) {
    my $f = Future->new;
    is_refcount($f, 1, 'refcount is 1');
    retain_future($f);
    is_refcount($f, 2, 'refcount is now 2');
    $f->$resolution($resolution eq 'cancel' ? () : '...');
    is_refcount($f, 1, 'refcount is back to 1 after ' . $resolution);
    dispose($f);
    is($f, undef, 'goes away after dispose');
}

{
    ok(retain_future(Future->done), 'can retain ->done Future');
    ok(retain_future(Future->fail("...")), 'can retain ->failed Future');
    ok(retain_future(Future->new->cancel), 'can retain ->cancelled Future');
}


done_testing;


