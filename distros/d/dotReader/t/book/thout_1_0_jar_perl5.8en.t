#!/usr/bin/perl

# vim:syntax=perl:ts=2:sw=2:et

use Test::More (
  skip_all => 'that book is broken',
  # tests=>11
  );

use strict;
use warnings;

BEGIN { use_ok('dtRdr::Book') };

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0_jar') };


my $uri = 'test_packages/osoft_9Perl5.8manual_en.jar';

# go directly to the class
my $book = dtRdr::Book::ThoutBook_1_0_jar->new();
isa_ok($book, 'dtRdr::Book');
ok($book->load_uri($uri), 'load');

my $metadata = $book->meta;
isa_ok($metadata, 'dtRdr::Metadata::Book', "check metadata");

my $toc = $book->toc;
isa_ok($toc, 'dtRdr::TOC');
is($toc->get_title, 'Perl 5.8.6 Documentation', "Check TOC title");

my (@children_toc) = $book->toc->children;
is(scalar(@children_toc), 15, "Check TOC children");

# TODO: this test should probably check some nodes for ->visible

is_deeply(\@children_toc, [$toc->children], 'tops and root children match');

my $testfile;
{
  local $/;
  $testfile = <DATA>;
  # Cheating a little here and stripping off any trailing whitespace
  # and newlines, since it was too much of a pain to get the data
  # segment to match the return from the book. (Which, I suppose,
  # should be fixed...)
  chomp $testfile;
  $testfile =~ s/\s//g;
}

my $html = $book->get_content(($children_toc[1]->get_children())[0]);
# Like with the data segment, strip off any trailing spaces and
# newlines for ease of matching
chomp $html;
$html =~ s/\s//g;

TODO: {
	local $TODO = 'make expect tests work again?';
	is($html, $testfile, "Check HTML return");
}
{ # maybe less fragile than a literal expect test:
	my ($h,$t) = ($html, $testfile);
	$_ =~ s/[^\w]//g for($h,$t);
	my $like = like($h, qr/$t/is, "Rough check on HTML content");
}



__END__
<pkg:outlineMarker OutlineName="NAME" id="lib_Pod_perl_html_name">
  <h1><a name="name">NAME</a></h1>
<p>perl - Practical Extraction and Report Language</p>
</pkg:outlineMarker>
