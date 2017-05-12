#!perl -T

use strict;
use warnings;

use Test::Most;

use URI::PathAbstract;
use URI;

plan qw/no_plan/;

my $u1 = URI::PathAbstract->new("/foo/goo", base => "http://example.com/");
my $u2 = URI::PathAbstract->new("../foo/", base => $u1);
my $u3 = URI::PathAbstract->new("hoo/foo", base => $u2);

is($u1->abs, "http://example.com/foo/goo");
is($u2->abs, "http://example.com/foo/");
is($u3->abs, "http://example.com/foo/hoo/foo");
is($u1->rel, "/foo/goo");
is($u2->rel, "../foo/");
is($u3->rel, "hoo/foo");
is($u1->path, "/foo/goo");
is($u2->path, "../foo/");
is($u3->path, "hoo/foo");

is(URI::PathAbstract->new(uri => "hoo", base => "http://foo/goo")->abs, "http://foo/hoo");
