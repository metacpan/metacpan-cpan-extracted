#!/usr/bin/env perl

# use Test::More tests => 23;
use Test::More qw(no_plan);

# look if we can load it
BEGIN { use_ok( 'WWW::Scroogle' ); }

# testing the construktor
can_ok('WWW::Scroogle','new');
ok(my $scroogle = WWW::Scroogle->new,'$object = WWW::Scroogle->new');
isa_ok($scroogle,'WWW::Scroogle');

# testing (set_)searchstring
my $searchstring = 'foobar';
can_ok('WWW::Scroogle', $_) for qw(searchstring set_searchstring);
eval{WWW::Scroogle->searchstring};
ok($@ =~ m/instance variable needed/, 'WWW::Scroogle->searchstring - fails (instance variable needed)');
eval{WWW::Scroogle->set_searchstring($searchstring)};
ok($@, 'WWW::Scroogle->set_searchstring('.$searchstring.') - fails (instance variable needed)');
eval{$scroogle->searchstring};
ok($@, '$object->searchstring - fails (no searchstring given jet)');
eval{$scroogle->set_searchstring()};
ok($@, '$object->set_searchstring() - fails (no searchstring given)');
eval{$scroogle->set_searchstring('')};
ok($@, '$object->set_searchstring("") - fails (nullstring given)');
ok($scroogle->set_searchstring($searchstring), '$object->set_searchstring("'.$searchstring.'")');
is($scroogle->searchstring,$searchstring,'$object->searchstring eq "'.$searchstring.'"');

# testing (default_|set_)language
my $language = 'de';
can_ok('WWW::Scroogle', $_) for qw(language set_language _default_language languages);
eval{WWW::Scroogle->language};
ok($@ =~ m/instance variable needed/, 'WWW::Scroogle->language - fails (instance variable needed)');
eval{WWW::Scroogle->set_language};
ok($@, 'WWW::Scroogle->set_language - fails (instance variable needed)');
is($scroogle->_default_language, '', '$object->_default_language eq ""');
is($scroogle->language, 'all', '$object->_default_language eq "all"');
ok($scroogle->set_language("en"), '$object->set_language("en")');
is($scroogle->language, 'en','$object->language eq "en"');
ok($scroogle->set_language(), '$object->set_language()');
is($scroogle->language, 'all','$object->language eq "all"');
eval{$scroogle->set_language("invalid")};
ok($@,'$object->set_language("invalid") - fails (invalid input)');
ok($scroogle->set_language('de'), '$object->set_language("de")');
is($scroogle->language, 'de', '$object->language eq "de"');
ok($scroogle->set_language('all'), '$object->set_language("all")');
is($scroogle->language, 'all', '$object->language eq "all"');

# testing (set_)num_results
can_ok('WWW::Scroogle', $_) for qw(num_results set_num_results);
eval {WWW::Scroogle->num_results};
ok($@ =~ m/instance variable needed/, 'WWW::Scroogle->num_results - fails (instance variable needed)');
eval {WWW::Scroogle->set_num_results(100)};
ok($@, 'WWW::Scroogle->set_num_results - fails (instance variable needed)');
eval {$scroogle->set_num_results("")};
ok($@, '$object->set_num_results("") - fails (odd number expected)');
eval {$scroogle->set_num_results('invalid')};
ok($@,'$object->set_num_results("invalid") - fails (odd number expected)');
eval {$scroogle->set_num_results(5.7)};
ok($@, '$object->set_num_results(5.7) - fails (odd number expected)');
eval {$scroogle->set_num_results(0)};
ok($@, '$object->set_num_results(0) - fails (minimum is 1result)');
is($scroogle->num_results,100,'$object->num_results == 100');
ok($scroogle->set_num_results(230), '$object->set_num_results(230)');
is($scroogle->num_results,230,'$object->num_results == 230');
ok($scroogle->set_num_results(), '$object->set_num_results()');
is($scroogle->num_results,100,'$object->num_results == 100');

# (n|has|delete|_add)(_)result(s)
for (qw(_add_result delete_results has_results nresults)) {
     can_ok('WWW::Scroogle', $_);
     eval "WWW::Scroogle->$_";
     ok($@ =~ m/instance variable needed/, 'WWW::Scroogle->'.$_.' - failed (instance variable needed)');
}
my $error = WWW::Scroogle->new;
ok(not($error->has_results), '$objectwithoutresults->has_results returns boolean false');
ok(not($error->delete_results), '$objectwithoutresults->delete_results returns boolean false');
eval {$error->nresults};
ok($@, '$objectwithoutresults->nresults - failed (no results avaible)');
eval {$scroogle->_add_result()};
ok($@ =~ m/hash/, '$object->_add_result() - failed (no options hash given)');
eval {$scroogle->_add_result({})};
ok($@ =~ m/no url/, '$object->_add_result({}) - failed (no url given)');
eval {$scroogle->_add_result({url => 'a.b.c',})};
ok($@ =~ m/no position/, '$object->_add_result({url=>"a.b.c",})');
ok($scroogle->_add_result({url => 'a.b.c',position => '1'}), '$object->_add_results({valid_options})');
ok($scroogle->has_results, '$object->has_results');
is($scroogle->nresults, 1, '$object->nresults == 1');
my $result = $scroogle->{results}->[0];
isa_ok($result, 'WWW::Scroogle::Result');
is($result->language, 'all', '$result->language eq "all"');
is($result->position, 1, '$result->position == 1');
is($result->searchstring, 'foobar', '$result->searchstring eq "foobar"');
is($result->url, 'a.b.c', '$result->url eq "a.b.c"');
ok($scroogle->delete_results, '$object->delete_results');
ok(not($scroogle->has_results), '$object->has_results returns boolean false');

# perform_search
can_ok('WWW::Scroogle', $_) for qw(perform_search);
eval {WWW::Scroogle->perform_search};
ok($@ =~ m/instance variable needed/,'WWW::Scroogle->perform-search - failed (instance variable needed)');
$error = WWW::Scroogle->new;
eval {$error->perform_search};
ok($@ =~ m/searchstring/,'object-without-searchstring->perform_search - failed (no searchstring given)');
ok($scroogle->perform_search, '$object->perform_search');
is($scroogle->nresults, 100, '$object->nresults == 100');
is(($scroogle->get_results)[0]->searchstring, 'foobar', '$result->searchstring eq "foobar"');
isa_ok(($scroogle->get_results)[0], 'WWW::Scroogle::Result');
ok($scroogle->set_num_results(133),'$object->set_num_results(133)');
ok($scroogle->perform_search, '$object->perform_search');
is($scroogle->nresults, 133, '$object->nresults == 100');
isa_ok(($scroogle->get_results)[0], 'WWW::Scroogle::Result');
ok($scroogle->set_language('de'), '$object->set_language("de")');
ok($scroogle->set_num_results(200), '$object->set_num_results(200)');
ok($scroogle->perform_search, '$object->perform_search');
is($scroogle->nresults, 200, '$object->nresults == 200');
is(($scroogle->get_results)[0]->language, 'de', '$result->language eq "de"');
isa_ok(($scroogle->get_results)[0], 'WWW::Scroogle::Result');

# get_result(s)
can_ok('WWW::Scroogle', $_) for qw(get_results get_result);
eval {WWW::Scroogle->get_results};
ok($@ =~ m/instance variable needed/, 'WWW::Scroogle->get_results - failed (instance variable needed)');
eval {WWW::Scroogle->get_result};
ok($@ =~ m/instance variable needed/, 'WWW::Scroogle->get_result - failed (instance variable needed)');
eval {$error->get_results};
ok($@ =~ m/result/, '$objectwithoutresults->get_results - failed (no results avaible)');
eval {$error->get_result(1)};
ok($@ =~ m/results/, '$objectwithoutresults->get_result(1) - failed (no results avaible)');
eval {$error->get_result};
ok($@ =~ m/no value given/, '$object->get_result - failed (no value given)');
ok(my @results = $scroogle->get_results, 'my @results = $object->get_results');
isa_ok($results[0], 'WWW::Scroogle::Result');
is($results[0]->position, 1, '$results[0]->position == 1');
ok($result = $scroogle->get_result(1), 'my $result = $object->get_result(1)');
isa_ok($result, 'WWW::Scroogle::Result');
is($result->position, 1, '$result->position == 1');

# get_results_matching
can_ok('WWW::Scroogle', $_) for qw(get_results_matching);
eval {WWW::Scroogle->get_results_matching};
ok($@ =~ m/instance variable needed/, 'WWW::Scroogle->get_result - failed (instance variable needed)');
eval {$scroogle->get_results_matching};
ok($@ =~ m/string/, '$object->positions - failed (no string given)');
eval {$error->get_results_matching("foobar")};
ok($@ =~ m/result/, '$objectwithoutresults->get_results_matching("foobar") - failed (no results avaible)');
ok(not($scroogle->get_results_matching("asdfghjkl")), '$object->get_results_matching("asdfghjkl") - returns boolean false (found nothing)');
ok(@results = $scroogle->get_results_matching("foo"), 'my @results = $object->get_results_matching("foo")');
ok(scalar(@results) >= 1, 'scalar(@results ) >= 1');
isa_ok($results[0], 'WWW::Scroogle::Result');

# position(s)
can_ok('WWW::Scroogle', $_) for qw(position positions);
eval {WWW::Scroogle->position};
ok($@ =~ m/instance variable needed/, 'WWW::Scroogle->position - failed (instance variable needed)');
eval {WWW::Scroogle->positions};
ok($@ =~ m/instance variable needed/, 'WWW::Scroogle->positions - failed (instance variable needed)');
eval {$scroogle->position};
ok($@ =~ m/string/, '$object->position - failed (no string given)');
eval {$scroogle->positions};
ok($@ =~ m/string/, '$object->positions - failed (no string given)');
eval {$error->position("foobar")};
ok($@ =~ m/result/, '$objectwithoutresults->position("foobar") - failed (no results avaible)');
eval {$error->positions("foobar")};
ok($@ =~ m/result/, '$objectwithoutresults->positions("foobar") - failed (no results avaible)');
ok($scroogle->position("foo"), '$object->position("foo") - returns boolean true (found something)');
ok($scroogle->positions("foo"), '$object->positions("foo") - returns boolean true (found something)');
ok($scroogle->position(qr(\w+)), '$object->position("\w+") - returns boolean true (found something)');
ok($scroogle->positions(qr(\w+)), '$object->position("\w+") - returns boolean true (found something)');
ok(not($scroogle->position("asdfghjkl")), '$object->position("asdfghjkl") - returns boolean false (found nothing)');
ok(not($scroogle->positions("asdfghjkl")), '$object->position("asdfghjkl") - returns boolean false (found nothing)');
