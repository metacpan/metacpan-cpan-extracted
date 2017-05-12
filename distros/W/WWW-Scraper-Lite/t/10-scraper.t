# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More tests => 14;

our $PKG = 'WWW::Scraper::Lite';

use_ok($PKG);

{
  my $s = $PKG->new;
  isa_ok($s, $PKG);
}

{
  my $s  = $PKG->new;
  my $ua = $s->ua;
  isa_ok($ua, 'LWP::UserAgent');
  my $ua2 = $s->ua;
  is($ua, $ua2, 'cached useragent');
}

{
  my $s = $PKG->new;
  ok($s->enqueue(qw(one two)), 'enqueue two items');
  is($s->dequeue(), 'one', 'dequeue first');
}

{
  my $s = $PKG->new;
  is($s->url_remove_anchor(), undef, 'remove anchor undef');
  is($s->url_remove_anchor('http://foo.com/bar#baz'), 'http://foo.com/bar', 'remove anchor');
}

{
  my $s = $PKG->new({
		     current => {
				 url => 'http://site.com/foo/bar',
				},
		    });

  is($s->url_make_absolute(), '', 'make_absolute undef');
  is($s->url_make_absolute('http://foo.com/'), 'http://foo.com/', 'make_absolute already absolute');
  is($s->url_make_absolute('/foo/bar'), 'http://site.com/foo/bar', 'make_absolute relative to root');
  is($s->url_make_absolute('baz.shtml'), 'http://site.com/foo/baz.shtml', 'make_absolute relative');
}

{
  my $ua = {};
  bless $ua, 'ua';
  *{ua::get}     = sub { my $self = shift; push @{$self->{in}}, \@_; return $ua; };
  *{ua::content} = sub { return q[<html><body><a href="http://foo.com/bar.baz"></a></html>]; };

  my $s = $PKG->new({
		     ua => $ua,
		    });
  my $results;
  ok($s->crawl('http://foo.com/', {
				   '//a' => sub { shift; my $x = shift; $results = $x->attr('href'); },
				  }), 'crawl return value');

  is($results, 'http://foo.com/bar.baz', 'parsed XPath node href');
}
