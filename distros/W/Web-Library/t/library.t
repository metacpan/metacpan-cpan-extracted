#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";
use Web::Library;
use Test::More;
use Test::Differences qw(eq_or_diff);
my $manager = Web::Library->new;
$manager->mount_library({ name => 'Foo' });
$manager->mount_library({ name => 'Bar', version => '1.2.3' });
eq_or_diff [ $manager->include_paths ],
  [qw(/foo-path/to/latest /bar-path/to/1.2.3)], 'include_paths() works';
subtest 'css_assets_for', sub {
    eq_or_diff [ $manager->css_assets_for('Foo') ],
      [qw(/css/foo-one.css /css/foo-two.css)], 'css_assets_for("Foo") works';
    eq_or_diff [ $manager->css_assets_for('Foo', 'Bar') ],
      [qw(/css/foo-one.css /css/foo-two.css /css/bar-one.css /css/bar-two.css)],
      'css_assets_for("Foo", "Bar") works';
};
subtest 'javascript_assets_for', sub {
    eq_or_diff [ $manager->javascript_assets_for('Foo') ],
      [qw(/js/foo-three.js /js/foo-four.js)], 'js_assets_for("Foo") works';
    eq_or_diff [ $manager->javascript_assets_for('Foo', 'Bar') ],
      [qw(/js/foo-three.js /js/foo-four.js /js/bar-three.js /js/bar-four.js)],
      'javascript_assets_for("Foo", "Bar") works';
};
subtest 'css_link_tags_for', sub {
    my $f1 = '<link href="/css/foo-one.css" rel="stylesheet">';
    my $f2 = '<link href="/css/foo-two.css" rel="stylesheet">';
    my $b1 = '<link href="/css/bar-one.css" rel="stylesheet">';
    my $b2 = '<link href="/css/bar-two.css" rel="stylesheet">';
    eq_or_diff $manager->css_link_tags_for('Foo'), "$f1\n$f2",
      'css_link_tags_for("Foo") works';
    eq_or_diff $manager->css_link_tags_for('Foo', 'Bar'), "$f1\n$f2\n$b1\n$b2",
      'css_link_tags_for("Foo", "Bar") works';
};
subtest 'script_tags_for', sub {
    my $f3 = '<script src="/js/foo-three.js" type="text/javascript"></script>';
    my $f4 = '<script src="/js/foo-four.js" type="text/javascript"></script>';
    my $b3 = '<script src="/js/bar-three.js" type="text/javascript"></script>';
    my $b4 = '<script src="/js/bar-four.js" type="text/javascript"></script>';
    eq_or_diff $manager->script_tags_for('Foo'), "$f3\n$f4",
      'script_tags_for("Foo") works';
    eq_or_diff $manager->script_tags_for('Foo', 'Bar'), "$f3\n$f4\n$b3\n$b4",
      'script_tags_for("Foo", "Bar") works';
};
done_testing;
