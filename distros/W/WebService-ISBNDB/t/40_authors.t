#!/usr/bin/perl

# $Id: 40_authors.t 40 2006-10-13 04:23:07Z  $

use strict;

use File::Basename 'dirname';
use Test::More;

use WebService::ISBNDB::API;
use WebService::ISBNDB::API::Authors;

my $dir = dirname $0;
do "$dir/util.pl";
do "$dir/DUMMY.pm";

WebService::ISBNDB::API->set_default_api_key(api_key());

open my $fh, "< $dir/xml/Authors-person_id=ray_randy_j.xml"
   or die "Error opening test XML: $!";
my $body = join('', <$fh>);
close($fh);
my @cats = ($body =~ /Category\s+category_id="(.*?)"/g);
my @subj = ($body =~ /Subject\s+subject_id="(.*?)"/g);

# 19 is the number of predefined tests, while @cats and @subj defines the
# number of on-the-fly tests.
plan tests => 19 + @cats + 2*@subj;

# Try creating a blank object, just to see what works:
my $author = WebService::ISBNDB::API::Authors->new();
isa_ok($author, 'WebService::ISBNDB::API::Authors');
# Check some defaults
is($author->get_protocol, 'REST', 'Default protocol set');
is($author->get_api_key, api_key(), 'Default API key');

# Change to the dummy agent class
WebService::ISBNDB::API->set_default_protocol('DUMMY');

# Now use a real value. Might as well be me...
my $author_id = 'ray_randy_j';
$author = WebService::ISBNDB::API::Authors->new($author_id);
isa_ok($author, 'WebService::ISBNDB::API::Authors');
is($author->get_id, $author_id, 'ID');
like($author->get_name, qr/^ray, randy j\.$/i, 'Name');
like($author->get_first_name, qr/^randy$/i, 'First name');
like($author->get_last_name, qr/^ray$/i, 'Last name');
is($author->get_dates, '', 'Dates');
ok($author->get_has_books, 'Has books (boolean)');

# Look at the categories
my $categories = $author->get_categories;
is(scalar(@$categories), scalar(@cats),
   'Categories count matches XML');
# Sub-tests for categories
for my $idx (0 .. $#$categories)
{
    is($categories->[$idx]->get_id, $cats[$idx], "ID of category $idx");
}

# Look at the subjects
my $subjects = $author->get_subjects;
is(scalar(@$subjects), scalar(@subj),
   'Subjects count matches XML');
# Sub-tests for subjects
for my $idx (0 .. $#$subjects)
{
    is($subjects->[$idx]->get_id, $subj[$idx], "ID of subject $idx");
    # Book count is different than if we'd asked for the subject directly.
    is($subjects->[$idx]->get_book_count, 1, "Book count of subject $idx");
}

# Try it from the factory model of the parent class. I won't be repeating the
# category tests-- if the few here pass, I'm satisfied.
$author = WebService::ISBNDB::API->new(Authors => $author_id);
isa_ok($author, 'WebService::ISBNDB::API::Authors');
is($author->get_id, $author_id, 'ID');
like($author->get_name, qr/^ray, randy j\.$/i, 'Name');
like($author->get_first_name, qr/^randy$/i, 'First name');
like($author->get_last_name, qr/^ray$/i, 'Last name');
is($author->get_dates, '', 'Dates');
ok($author->get_has_books, 'Has books (boolean)');

exit;
