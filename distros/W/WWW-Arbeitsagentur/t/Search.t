#!/usr/bin/perl -w 
use strict;
use warnings;

use Test::More tests => 11;
use Test::MockObject;
use Test::MockObject::Extends;
use Test::Exception;
use WWW::Mechanize::Link;

my $mech_mock = Test::MockObject->new;
$mech_mock->fake_module('WWW::Mechanize');
$mech_mock->set_true( qw/ add_header follow_link success form_number dump_content value untick submit_form/);
$mech_mock->fake_new('WWW::Mechanize');

use_ok('WWW::Arbeitsagentur::Search::FastSearchForWork');
use_ok('WWW::Arbeitsagentur::Search');

my $search = WWW::Arbeitsagentur::Search::FastSearchForWork->new(
								 path		=> 'download/',
								 job_typ	=> 1,
								 plz_filter	=> qr/.+/,
								 _module_test	=> 1,
								 beruf		=> 'Fachinformatiker/in - Anwendungsentwicklung',								 
								 );

is(ref($search), 'WWW::Arbeitsagentur::Search::FastSearchForWork', 'Create FastSearch Object');

$search = Test::MockObject::Extends->new( $search );
$search->set_true( qw/connect save_results collect_result_pages/ );

### select_job:

# no job in $self->beruf
$search->set_false( 'beruf' );
dies_ok( sub { $search->search() }, 'search dies without job to search for' );

# no job_typ in $self->beruf
$search->set_true( 'beruf' );
$search->set_false( 'job_typ' );
dies_ok( sub { $search->search() }, 'search dies without a specified job_type' );

# submit_form finds several jobs
## but we still find something we like
$search->set_true('job_typ');
$mech_mock->set_always('content' => 'Ergebnis der Suche nach Berufen');
$mech_mock->set_true( qw/follow_link/);
$search->set_always( 'results_count' => 3333 );
is( $search->search(), 3333, 'select_job may find several job descriptions');

## we find nothing good at all
# This won't work: $mech->follow_link is inside eval-block... 
# Mock may return whatever it wants and still fail.
#$mech_mock->set_false( 'follow_link');
#dies_ok( sub { $search->search() }, 'search dies if no job description was found');

# submit_form finds exactly 1 job
$mech_mock->set_always("content" => 'name="beruf" value="3333"');
is( $search->select_job(), 1, "select_job finds exactly one job description");

# content: is empty / found 0 jobs
$mech_mock->set_always("content" => 'no_job');
is( $search->select_job(), 0, "select_job finds no job description");

#### collect_result_pages:

# does not find a job result at all
$mech_mock->set_false('find_all_links');
$search->unmock('collect_result_pages');
is($search->collect_result_pages, 0, 'Search returns no results');

# find a job / applicant
$mech_mock->set_true('get');
$mech_mock->set_list('find_all_links' => (
					  WWW::Mechanize::Link->new( {'url' => 'http://localhost/'} ) ) );
is( $search->collect_result_pages, 1, 'Search returns 1 result');

# get job fails
$mech_mock->clear();
$mech_mock->set_false( qw/ get success/ );
is( $search->collect_result_pages, 0, 'get(result) fails.');

# job has no link to next

# job has link to next job

# module_test works.

# number of pages found?

### save page:

# result_index (1) returns zero length data

# extract_refnumber returns 0

## save with filename == sha256_hex

# extract_refnumber returns ($number)

# test: was data written?

# 

### save_results

# results_count == 0

# save_page fails

# "all_is_well"
