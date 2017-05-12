#!/usr/bin/perl

# $Id: 60_iterator.t 40 2006-10-13 04:23:07Z  $

use strict;
use vars qw($idx);

use File::Basename 'dirname';
use Test::More;

use WebService::ISBNDB::API;

my $dir = dirname $0;
do "$dir/util.pl";
do "$dir/DUMMY.pm";

WebService::ISBNDB::API->set_default_api_key(api_key());

# Read the data from the static XML files to set up the test-against values
my (@book_ids, $fh, $body, $count);

# Small subroutine to avoid repeating the extraction code
sub extract_ids
{
    (shift =~ /<BookData book_id="(.*?)"/gm);
}

# The first file has a different name-syntax:
open $fh, "< $dir/xml/Books-person_id=poe_edgar_allan.xml"
    or die "Error opening test XML: $!";
$body = join('', <$fh>);
close($fh);
push(@book_ids, extract_ids($body));

# The other 25 all follow the same syntax:
foreach (2 .. 26)
{
    open $fh, "< $dir/xml/Books-page_number=$_-person_id=poe_edgar_allan.xml"
        or die "Error opening test XML: $!";
    $body = join('', <$fh>);
    close($fh);
    push(@book_ids, extract_ids($body));
}

# Change to the dummy agent class
WebService::ISBNDB::API->set_default_protocol('DUMMY');

# 16 static tests, plus one test for each book ID.
plan tests => 16 + 2*@book_ids;

# First, basic object creation
my $iter = WebService::ISBNDB::Iterator->new({ request_args => {},
                                               contents     => [] });
isa_ok($iter, 'WebService::ISBNDB::Iterator');
is($iter->get_agent, WebService::ISBNDB::API->get_default_agent(),
   'Iterator inherited default agent');

# Get an author object for Poe, which is used to create the iterator
my $poe = WebService::ISBNDB::API->find(Authors => 'poe_edgar_allan');
# Get an iterator, a real one this time:
$iter = WebService::ISBNDB::API->search(Books => { author => $poe });
isa_ok($iter, 'WebService::ISBNDB::Iterator');

# Look at some of the basic attributes
is($iter->get_total_results, 252, 'Correct number of results');
is($iter->get_page_size, 10, 'Correct page size');
is($iter->get_page_number, 1, 'Correct page number');
is($iter->get_shown_results, $iter->get_page_size, 'Correct shown-results');
is($iter->get_index, 0, 'Correct (initial) index');

# Set a page-load hook, to test that
$iter->set_fetch_page_hook(sub { $count++ });
is(ref($iter->get_fetch_page_hook), 'CODE', 'Page-load hook set OK');

# Test first(), and by association test that it doesn't interfere with next()
my $book = $iter->first;
isa_ok($book, WebService::ISBNDB::API->class_for_type('Books'));
is($book->get_id, $book_ids[0], 'Book from "first" has correct ID');

# Test the iteration
$idx = 0;
while ($book = $iter->next)
{
    isa_ok($book, WebService::ISBNDB::API->class_for_type('Books'));
    is($book->get_id, $book_ids[$idx], "Book $idx has correct ID");
    $idx++;
}

# Test that the hook was called enough times
is($count, 25, 'Page-fetch hook called correctly');

# Test resetting
$iter->reset;
$book = $iter->first;
isa_ok($book, WebService::ISBNDB::API->class_for_type('Books'));
is($book->get_id, $book_ids[0], 'Book from "first/reset" has correct ID');

# Iterate again, just count this time
$idx = 0;
while ($book = $iter->next)
{
    $idx++;
}
is($idx, 252, 'Correct count after second iteration');

# Reset and call "all"
$iter->reset;
my @all = $iter->all;
is(scalar(@all), 252, 'Correct count from "all"');

exit;
