#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path tempdir );

# Author test: prove every committed "expected" in t/corpus/*.json still equals
# what the live upstream oracle produces. It does that by regenerating a
# throwaway copy of each corpus file through the real maint/corpus-regen (which
# runs node maint/oracle.js against the pinned upstream) and byte-comparing the
# regenerated copy to the committed file. Identical => the corpus is current;
# a diff => a committed expectation is stale, so run maint/corpus-regen.
#
# Needs upstream/ (maint/fetch-upstream) and node; skips clearly without them.

my $root    = path(__FILE__)->parent->parent;
my $upstream = $root->child('upstream/nunjucks/nunjucks/index.js');
my $regen    = $root->child('maint/corpus-regen');
my $corpus   = $root->child('t/corpus');

plan skip_all => "upstream/ not present -- run maint/fetch-upstream"
  unless $upstream->is_file;
plan skip_all => "node not runnable"
  unless system( 'node', '-e', '0' ) == 0;
plan skip_all => "maint/corpus-regen not found"
  unless $regen->is_file;

my @files = sort $corpus->children(qr/\.json$/);
plan skip_all => "no corpus files in $corpus" unless @files;

# Copy the committed corpus into a tempdir and regenerate the copies in place.
my $tmp = tempdir;
my @copies = map { my $c = $tmp->child( $_->basename ); $_->copy($c); $c } @files;

my $rc = system( 'node', "$regen", map { "$_" } @copies );
is( $rc, 0, 'maint/corpus-regen ran against the live oracle' ) or do {
  done_testing;
  exit;
};

for my $i ( 0 .. $#files ) {
  my $name = $files[$i]->basename;
  my $committed = $files[$i]->slurp_raw;
  my $fresh     = $copies[$i]->slurp_raw;
  ok( $fresh eq $committed, "$name matches the live oracle" )
    or diag("$name is stale -- run: maint/corpus-regen");
}

done_testing;
