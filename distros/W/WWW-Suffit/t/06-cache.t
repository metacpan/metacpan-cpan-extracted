#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Test::More;
use WWW::Suffit::Cache;

my $cache = WWW::Suffit::Cache->new(
        max_keys   => 3,
    );
is $cache->max_keys, 3, "Max keys"; #note "Max keys   : " . $cache->max_keys;
is !!$cache->expiration, !!0, "Expiration"; #note "Expiration : " . $cache->expiration;

subtest 'Set and Get methods' => sub {
    is $cache->get('foo'), undef, 'No result';
    $cache->set(foo => '123');
    is($cache->get('foo'), '123', "Get") or return;
};

subtest 'Too much entities (2 max)' => sub {
    $cache->max_keys(2);
    $cache->set(foo => 'bar');
    is $cache->get('foo'), 'bar', 'Foo=bar';

    $cache->set(bar => 'baz');
    is $cache->get('foo'), 'bar', 'Foo=bar';
    is $cache->get('bar'), 'baz', 'Bar=baz';

    $cache->set(baz => 'qux');
    is $cache->get('foo'), undef, 'no result';
    is $cache->get('bar'), 'baz', 'Bar=baz';
    is $cache->get('baz'), 'qux', 'Baz=qux';

    $cache->set(qux => 123);
    is $cache->get('foo'), undef, 'no result';
    is $cache->get('bar'), undef, 'no result';
    is $cache->get('baz'), 'qux', 'Baz=qux';
    is $cache->get('qux'), 123,   'Qux=123';

    $cache->max_keys(1)->set(one => 1)->set(two => 2);
    is $cache->get('one'), undef, 'no result';
    is $cache->get('two'), 2,     'Two=2';
    #note explain $cache;
};

subtest 'Expiration' => sub {
    $cache->max_keys(0);
    is $cache->max_keys, 0, "Max keys = 0";

    $cache->expiration(1);
    is $cache->expiration, 1, "Expiration = 1";

    $cache->set(foo => 'a', 1);
    $cache->set(bar => 'b', 2);
    $cache->set(baz => 'c', 1);

    sleep 1;

    is $cache->get('foo'), undef, 'no result';
    is $cache->get('bar'), 'b', 'Bar=b';
    is $cache->get('baz'), undef, 'no result';

    #note explain $cache;
};

subtest 'Counts' => sub {
    is $cache->count, 2, "Count";
};

subtest 'Remove' => sub {
    $cache->set(qwe => 1, 0);
    is $cache->get('qwe'), 1, 'qwe=1';

    $cache->set(asd => 2, 0);
    is $cache->get('asd'), 2, 'asd=2';

    is $cache->count, 4, "Count";
    $cache->remove('qwe')->remove('asd');
    is $cache->count, 2, "Count";
    #note explain $cache;
};

subtest 'Purge and cleanup' => sub {
    sleep 2;
    is $cache->purge->count, 1, "No expired data in cache";
    is $cache->clean->count, 0, "No any data in cache";
    #note explain $cache;
};


done_testing;

1;

__END__

prove -lv t/06-cache.t