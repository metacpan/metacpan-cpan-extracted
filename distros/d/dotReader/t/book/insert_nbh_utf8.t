#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta

use strict;
use warnings;

use XML::Parser::Expat;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0') };
BEGIN { use_ok('dtRdr::Highlight') };

local $SIG{__WARN__};
my $test_book = 'test_packages/selection_check/book.xml';
(-e $test_book) or die "missing '$test_book' file!";

my $book = dtRdr::Book::ThoutBook_1_0->new();
ok($book, 'constructor');
ok($book->load_uri($test_book), 'load');

# setup the data
my $node = $book->toc;
ok($node, 'got node');
ok($node->get_title eq "FreeBSD Developers' Handbook", 'title check');

# pre-create the character cache
my $content = $book->get_content($node);

{
  # diag("end-of-node check");
  # search for:
  my $lwing  = '2-1. ';
  my $string = 'A sample .emacs file';
  my $rwing  = ' ';
  find_and_check($lwing, $string, $rwing, 'end-of-node check', 'D1');

}
$book->delete_highlight($_) for $book->node_highlights($node);
{
  my $lwing = '';
  my $string = do {open(my $fh, '<:utf8', 't/book/find_this.data') or die; local $/; <$fh>;};
  chomp($string);
  my $rwing = '';
  find_and_check($lwing, $string, $rwing, 'full page select', 'D2');
}
$book->delete_highlight($_) for $book->node_highlights($node);
{
  my $lwing = 'Important: ';
  my $string = 'THIS DOCUMENTATION IS PROVIDED';
  my $rwing = '';
  my $content = find_and_check($lwing, $string, $rwing, 'odd middle thing', 'D3');
  ok($content =~ m/Important:<\/b> <a[^\>]+><\/a><span/, 'in the right spot?');
}
$book->delete_highlight($_) for $book->node_highlights($node);
{
  my $lwing = 'THIS DOCUMENTATION IS PROVIDED ';
  my $string = 'BY THE FREEBSD DOCUMENTATION PROJECT';
  my $rwing = ' "AS IS" AND ANY EXPRESS';
  my $content = find_and_check($lwing, $string, $rwing, 'odd middle thing 2', 'D4');
  ok($content =~/PROVIDED <a[^>]+><\/a><span.*>BY THE FREEBSD/, 'in the right spot?');
}
$book->delete_highlight($_) for $book->node_highlights($node);

########################################################################
sub find_and_check {
  my ($lwing, $string, $rwing, $label, $dbg) = @_;
  $label ||= '';
  # feed it a node, string, and two wings
  my $range = eval {$book->locate_string($node, $string, $lwing, $rwing); };
  my $ok = is($@, '', "still alive - '$label'");
  SKIP: {
    $ok or (skip('locate failed', 3) and return); 
    # make sure it comes up with the right location
    isa_ok($range, 'dtRdr::Range') or return;

    my $highlight = dtRdr::Highlight->claim($range);
    isa_ok($highlight, 'dtRdr::Highlight');

    $book->add_highlight($highlight);

    my $content = eval { $book->get_content($node) };
    ok(! $@, "survived get_content - '$label'");

    # dump to file to debug
    if(defined($dbg) and $ENV{$dbg}) {
      # XXX really needs to use a dtRdr::Logger->dump(...) or something
      open(my $f, '>:utf8', '/tmp/thecontent');
      print $f $content;
    }
    # make $content smaller for diagnosibility
    #$content =~ s/.*$hl_id//s or die;
    #$content =~ s/To +get +the +most +out +of.*//s or die;
    #like($content, qr/<span class="[^"]*">organizes new and existing content<\/span/);
    return($content);
  } # end skip
}
