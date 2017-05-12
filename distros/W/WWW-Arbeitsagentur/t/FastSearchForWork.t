#!/usr/bin/perl -w 

use strict;
use warnings;

use Test::More tests => 7;
use Test::MockObject;
use Test::MockObject::Extends;
use Test::Exception;

my $mech_mock = Test::MockObject->new;
$mech_mock->fake_module('WWW::Mechanize');
$mech_mock->set_true( qw/add_header follow_link success form_number dump_content value untick submit_form/);
$mech_mock->fake_new('WWW::Mechanize');

use_ok('WWW::Arbeitsagentur::Search::FastSearchForWork');

my $search = WWW::Arbeitsagentur::Search::FastSearchForWork->new(
								 path		=> 'download/',
								 job_typ	=> 1,
								 plz_filter	=> qr/.+/,
								 _module_test	=> 1,
								 beruf		=> 'Fachinformatiker/in - Anwendungsentwicklung',								 
								 );

is(ref($search), 'WWW::Arbeitsagentur::Search::FastSearchForWork', 'Create FastSearch Object');

$search = Test::MockObject::Extends->new( $search );
$search->set_true( qw/select_job connect save_results collect_result_pages results_count/ );
is($search->search(), 1, "Search is succcessful if all is well.");

$mech_mock->set_false('success');
throws_ok( sub { $search->search() },
	   qr/Konnte die Seite mit der Schnellsuche für Arbeitnehmer nicht finden/, 
	   "die if search form is unavailable");

$mech_mock->set_series('success', 1, 0);
throws_ok( sub { $search->search() },
	   qr/Die Schnellsuche konnte nicht durchgeführt werden/, 
	   "die if fast search fails mysteriously");

$mech_mock->set_true('success');
$search->set_false('select_job');
throws_ok( sub { $search->search() }, qr/Konnte keinen Beruf auswählen/, 
	   "die if job-selection is unsuccessful");

$search->set_false('connect');
throws_ok( sub { $search->search() }, qr/Konnte keine Verbindung zur BA aufbauen/,
	   "die if connection fails.");
