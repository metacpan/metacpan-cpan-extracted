#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Differences qw(eq_or_diff);

package Foo;
use Moose;
with qw(Web::Library::SimpleAssets);

sub version_map {
    +{  default => {
            css        => [ '/css/one.css', '/css/two.css' ],
            javascript => [ '/js/one.js',   '/js/two.js' ],
        },
        '1.2.3' => {
            css        => [ '/css/three.css', '/css/four.css' ],
            javascript => [ '/js/three.js',   '/js/four.js' ],
        },
    };
}

package main;
my $foo = Foo->new;
subtest 'css_assets_for', sub {
    eq_or_diff [ $foo->css_assets_for('2.4.6') ],
      [ '/css/one.css', '/css/two.css' ], 'css_assets_for("2.4.6") works';
    eq_or_diff [ $foo->css_assets_for('1.2.3') ],
      [ '/css/three.css', '/css/four.css' ],
      'css_assets_for("1.2.3") works';
};
subtest 'javascript_assets_for', sub {
    eq_or_diff [ $foo->javascript_assets_for('2.4.6') ],
      [ '/js/one.js', '/js/two.js' ],
      'javascript_assets_for("2.4.6") works';
    eq_or_diff [ $foo->javascript_assets_for('1.2.3') ],
      [ '/js/three.js', '/js/four.js' ],
      'javascript_assets_for("1.2.3") works';
};
done_testing;
