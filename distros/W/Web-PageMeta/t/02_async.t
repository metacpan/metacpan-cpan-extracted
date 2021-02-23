#! /usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::Most;
use Web::PageMeta;
use AnyEvent;
use Future;

subtest 'wait_all' => sub {

    # fake urls indicating only milliseconds to delay response
    my @pages = ('30', '10', '20');
    my (@execs, @execs_img);
    my @pms = map {Web::PageMeta->new(url => $_, _ua => Test::Mock::Future::HTTP->new,)} @pages;
    my @fts = map {
        my $pm = $_;
        $pm->fetch_page_meta_ft->on_done(
            sub {
                push(@execs, $pm->url->as_string);
            }
        )->on_fail(
            sub {
                diag($pm->url->as_string . ' meta Future failed with: ' . $_[0]);
            }
        );
    } @pms;
    my @fts_images = map {
        my $pm = $_;
        $pm->fetch_image_data_ft->on_done(
            sub {
                push(@execs_img, $pm->url->as_string);
            }
        )->on_fail(
            sub {
                diag($pm->url->as_string . ' image Future failed with: ' . $_[0]);
            }
        );
    } @pms;

    Future->wait_all(@fts_images)->get;

    eq_or_diff(
        [map {$_->state} @fts, @fts_images],
        [map {'done'} @fts, @fts_images],
        'all Futures done'
    );

    eq_or_diff(\@execs,     ['10', '20', '30'], 'Future->wait_all()');
    eq_or_diff(\@execs_img, ['10', '20', '30'], 'Future->wait_all()');
};

subtest 'fmap_void' => sub {

    # fake urls indicating only milliseconds to delay response
    my @pages = ('30', '10', '5');
    my @execs_img;
    my @pms = map {Web::PageMeta->new(url => $_, _ua => Test::Mock::Future::HTTP->new,)} @pages;

    use Future::Utils qw( fmap_void );
    fmap_void(
        sub {
            my $pm = $_;
            return $pm->fetch_image_data_ft->on_done(
                sub {
                    push(@execs_img, $pm->url->as_string);
                }
            )->on_fail(
                sub {
                    diag($pm->url->as_string . ' meta Future failed with: ' . $_[0]);
                }
            );
        },
        foreach    => [@pms],
        concurrent => 2
    )->get;

    eq_or_diff(\@execs_img, ['10', '5', '30'], 'fmap_void()->get()');
};

subtest 'fail on non-200' => sub {
    # this test will try real http request
    # http request will fail with or without functioning internet connection
    my $ok_http_fail;
    my $ft =
        Web::PageMeta->new(url => 'https://www.meon.eu/Web-PageMeta-notfound',)->fetch_page_meta_ft;
    $ft->on_fail(
        sub {
            $ok_http_fail = 1;
        }
    );
    $ft->on_done(
        sub {
            $ok_http_fail = 0;
        }
    );
    $ft->await;
    is($ok_http_fail, 1, 'future fail() on non-200 status');
};

done_testing();

package Test::Mock::Future::HTTP;

use Moose;
use AnyEvent::Future;

sub http_get {
    my ($self, $url) = @_;

    return Future->fail('unsupported url "' . $url . '"')
        if ($url !~ m{^/?(\d+)([.]jpg)?$});
    my ($delay, $is_image) = ($1, $2);

    my $body;
    if ($is_image) {
        $delay = 10;
        $body  = 'image:' . $url;
    }
    else {
        $body = '<html><head><meta property="og:image" content="' . $url . '.jpg"/></head></html>';
    }

    my $ft = AnyEvent::Future->new();
    my $w;
    $w = AnyEvent->timer(
        after => ($delay / 1000),
        cb    => sub {
            $ft->done($body, {Status => 200});
            $w = undef;
        }
    );
    return $ft;
}

1;
