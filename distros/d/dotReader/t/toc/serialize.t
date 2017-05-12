#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::TOC');   }
BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0_jar');  }
BEGIN { use_ok('dtRdr::Range'); }

{ # load a real book
  my $test_book = 'test_packages/0_jars/thout1_test.jar';
  (-e $test_book) or die "missing '$test_book' file!";

  my $book = dtRdr::Book::ThoutBook_1_0_jar->new();
  ok($book, 'book constructor');
  ok($book->load_uri($test_book), 'load');

  my $toc = $book->toc;

  # check the serialization
  my $yaml = $toc->yaml_dump;
  my $re_toc = dtRdr::TOC->yaml_load($yaml, $book);

  # XXX is_deeply is really slow here, do we really need it?
  my $do_deeply = 0;
  if($do_deeply) { # correct, but slow
    is_deeply($re_toc, $toc);
  }
  else {
    #diag('check reloaded');
    _my_is_deeply($toc, $re_toc, $book);
# XXX the $toc has been hacked-up, don't use it past here XXX
  }

  # check that reference optimization is working
  my $re_toc_ref = dtRdr::TOC->yaml_load(\$yaml, $book);
  if($do_deeply) { # correct, but slow
    is_deeply($re_toc_ref, $toc);
  }
  else {
    #diag('check reloaded 2');
    _my_is_deeply($toc, $re_toc_ref, $book);
  }

  # load a version 0.1 toc off of disk and repeat
  use File::Basename;
  my $version0_1 = do { open(my $fh, '<', 
    dirname(__FILE__) . '/thout1_test_v0.1.toc'
    ) or die 'cannot open';
    local $/;
    <$fh>;
  };
  ok($version0_1, 'got YAML content');
  my $v0_1ref = dtRdr::TOC->yaml_load($version0_1, $book);
  ok($v0_1ref, 'loaded from disk');
  isa_ok($v0_1ref, 'dtRdr::TOC');
  if($do_deeply) { # correct, but slow
    is_deeply($v0_1ref, $toc);
  }
  else {
    #diag('check reloaded from disk');
    _my_is_deeply($toc, $v0_1ref, $book);
  }
}

########################################################################
# speed-optimized test
sub _my_is_deeply {
  my ($toc, $re, $book) = @_;

  $toc->_rmap(sub {
    my $node = shift;
    foreach my $child (@{$node->{children}}) {
      delete($child->{_root});
    }
    delete($node->{book});
  });
  delete($toc->{_index});
  delete($re->{_index});

  # and the other
  $re->_rmap(sub {
    my $node = shift;
    foreach my $child (@{$node->{children}}) {
      my $root = delete($child->{_root});
      is($root, $re, 'check root on ' . $child->id);
    }
    my $b = delete($node->{book});
    is($b, $book, 'check book on ' . $node->id);
  });
  is_deeply($toc, $re);
}
