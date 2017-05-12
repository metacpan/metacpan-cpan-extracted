#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.016000;
use autodie;

# http://blog.livedoor.jp/sasata299/archives/51277861.html

package Blog {
    use Mouse;

    has 'id' => ( is => 'rw' );
    has 'name' => (is => 'rw');
    has 'url' => (is => 'rw');

    our @STORAGE;
    sub save {
        my $self = shift;
        push @STORAGE, $self;
    }
    sub count { 0+@STORAGE }
}

package Tag {
    use Mouse;

    our @STORAGE;
    sub save {
        my $self = shift;
        push @STORAGE, $self;
    }
    sub count { 0+@STORAGE }
}

package main {
    use Test::Ika;
    use Test::Should;

    describe 'Saving blogs' => sub {
        it 'can save a new blog' => sub {
            Blog->new->save->should_be_ok;
        };
        it 'was saved on DB' => sub {
            (sub { Blog->new()->save })->should_change(sub { Blog->count() });
        };
    };

    describe 'Listing blogs' => sub {
        before_all {
            load_fixture()
        };

        it 'saved three blogs' => sub {
            Blog->count->should_be_equal(3)
        };
        # ...
    };

    runtests;
}

sub load_fixture {
    @Blog::STORAGE = ();

    Blog->new(
        id   => 1,
        name => "sasata299's blog",
        url  => 'http://blog.livedoor.jp/sasata299/',
    )->save;
    Blog->new(
        id   => 2,
        name => 'zozomのページ',
        url  => 'http://www.zozom.net',
    )->save;
    Blog->new(
        id   => 3,
        name => 'sasata299のページ',
        url  => 'http://sasata299.com',
    )->save;
}

