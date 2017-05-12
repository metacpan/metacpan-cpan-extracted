#!/usr/bin/perl

# $Id: 30_subjects.t 40 2006-10-13 04:23:07Z  $

use strict;

use File::Basename 'dirname';
use Test::More;

use WebService::ISBNDB::API;
use WebService::ISBNDB::API::Subjects;

my $dir = dirname $0;
do "$dir/util.pl";
do "$dir/DUMMY.pm";

WebService::ISBNDB::API->set_default_api_key(api_key());

open my $fh, "< $dir/xml/Subjects-subject_id=perl_computer_program_language.xml"
   or die "Error opening test XML: $!";
my $body = join('', <$fh>);
close($fh);
my $book_count = ($body =~ /book_count="(\d+)"/)[0];
my @cats = ($body =~ /Category\s+category_id="(.*?)"/g);

# 18 is the number of predefined tests, while @cats defines the number of
# on-the-fly tests.
plan tests => 18 + @cats;

# Try creating a blank object, just to see what works:
my $subject = WebService::ISBNDB::API::Subjects->new();
isa_ok($subject, 'WebService::ISBNDB::API::Subjects');
# Check some defaults
is($subject->get_protocol, 'REST', 'Default protocol set');
is($subject->get_api_key, api_key(), 'Default API key');

# Change to the dummy agent class
WebService::ISBNDB::API->set_default_protocol('DUMMY');

# Now use a real value. I like this one, because it's where my book is.
my $subject_id = 'perl_computer_program_language';
$subject = WebService::ISBNDB::API::Subjects->new($subject_id);
isa_ok($subject, 'WebService::ISBNDB::API::Subjects');
is($subject->get_id, $subject_id, 'ID');
like($subject->get_name, qr/^Perl \(Computer program language\)$/i, 'Name');
is($subject->get_book_count, $book_count, 'Book count');
is($subject->get_marc_field, 650, 'MARC field');
is($subject->get_marc_indicator_1, '', 'MARC indicator 1');
is($subject->get_marc_indicator_2, '0', 'MARC indicator 2');

# Look at the categories
my $categories = $subject->get_categories;
is(scalar(@$categories), scalar(@cats),
   'Categories count matches XML');
# Sub-tests for categories
for my $idx (0 .. $#$categories)
{
    is($categories->[$idx]->get_id, $cats[$idx], "ID of category $idx");
}

# Try it from the factory model of the parent class. I won't be repeating the
# category tests-- if the few here pass, I'm satisfied.
$subject = WebService::ISBNDB::API->new(Subjects => $subject_id);
isa_ok($subject, 'WebService::ISBNDB::API::Subjects');
is($subject->get_id, $subject_id, 'ID');
like($subject->get_name, qr/^Perl \(Computer program language\)$/i, 'Name');
is($subject->get_book_count, $book_count, 'Book count');
is($subject->get_marc_field, 650, 'MARC field');
is($subject->get_marc_indicator_1, '', 'MARC indicator 1');
is($subject->get_marc_indicator_2, '0', 'MARC indicator 2');

exit;
