# $Id: use.t,v 1.27 2008-07-14 03:11:10 Martin Exp $

use strict;
use warnings;

use ExtUtils::testlib;
use Test::More 'no_plan';

use IO::Capture::Stderr;
ok(my $oICE = IO::Capture::Stderr->new);

BEGIN
  {
  use_ok('WWW::Search');
  use_ok('WWW::SearchResult');
  use_ok('WWW::Search::Result');
  use_ok('WWW::Search::Test',
         qw(new_engine run_gui_test run_test skip_test count_results));
  } # end of BEGIN block

my @as;
eval { @as = &WWW::Search::installed_engines };
ok(0 < scalar(@as), 'any installed engines');
diag('FYI the following backends are already installed (including ones in this distribution): '. join(', ', sort @as));
my %hs = map { $_ => 1 } @as;
my $sBackend = 'AltaVista';
$ENV{HARNESS_PERL_SWITCHES} ||= '';
if (exists $hs{$sBackend} && ($ENV{HARNESS_PERL_SWITCHES} =~ m!Devel::Cover!))
  {
  diag(qq{You are running 'make cover' and I found WWW::Search::$sBackend installed, therefore I will do some live searches to enhance the coverage testing...});
  my $o = new WWW::Search($sBackend);
  $o->native_query('Vader');
  $o->maximum_to_retrieve(111);
  my @ao = $o->results();
  } # if

# Make sure an undef query does not die;
my $o1 = new WWW::Search; # NO BACKEND SPECIFIED
ok(ref $o1);
my @ao = $o1->results();
ok(ref $o1->response);
ok($o1->response->is_error);
ok(scalar(@ao) == 0);
# Make sure an empty query does not die;
my $o2 = new WWW::Search; # NO BACKEND SPECIFIED
ok(ref $o2);
$o2->native_query(''); # EMPTY STRING
my @ao2 = $o2->results();
ok(ref $o2->response);
ok($o2->response->is_error);
ok(scalar(@ao2) == 0);
# Tests for approx_result_count:
is($o2->approximate_result_count(3), 3);
is($o2->approximate_result_count(undef), 3);
is($o2->approximate_result_count(''), 3);
is($o2->approximate_result_count(0), 0);
is($o2->approximate_result_count(2), 2);
is($o2->approximate_hit_count(undef), 2);
is($o2->approximate_hit_count(-1), 2);
# Test for what happens when a backend is not installed:
my $o3;
eval { $o3 = new WWW::Search('No_Such_Backend') };
like($@, qr{(?i:can not load backend)});
my $iCount = 44;
my $o4 = new WWW::Search('Null::Count',
                         '_null_count' => $iCount,
                        );
# Get result_count before submitting query:
is($o4->approximate_result_count, $iCount);
# Get some results:
ok($o4->login, 'login');
$o4->maximum_to_retrieve($iCount/2);
my $iCounter = 0;
while ($o4->next_result)
  {
  $iCounter++;
  } # while
is($iCounter, $iCount/2, 'next_result stops at maximum_to_retrieve');
$o4->maximum_to_return($iCount * 2);
while ($o4->next_result)
  {
  $iCounter++;
  } # while
is($iCounter, $iCount, 'next_result goes to end of cache');
ok($o4->logout, 'logout');
ok($o4->response, 'response');
ok($o4->submit, 'submit');
is($o4->opaque, undef, 'opaque is undef');
$o4->opaque('hello');
is($o4->opaque, 'hello', 'opaque is hello');
$o4->seek_result(undef);
$o4->seek_result(-1);
$o4->seek_result(3);
is(WWW::Search::escape_query('+hi +mom'), '%2Bhi+%2Bmom', 'escape');
is(WWW::Search::unescape_query('%2Bhi+%2Bmom'), '+hi +mom', 'unescape');
# Use a backend for a second time (just to exercise the code in
# Search.pm):
my $o5 = new WWW::Search('Null::Count');
# Test the version() function:
ok($o4->version, 'version defined in backend');
$o5 = new WWW::Search('Null::NoVersion');
is($o5->version, $WWW::Search::VERSION, 'default version');
# Test the maintainer() function:
ok($o4->maintainer, 'maintainer defined in backend');
is($o5->maintainer, $WWW::Search::MAINTAINER, 'default maintainer');
# Exercise / test the cookie_jar() function:
$o4->cookie_jar('t/cookies.txt');
my $oCookies = new HTTP::Cookies;
$o5->cookie_jar($oCookies);
$oICE->start;
eval { $o2->cookie_jar($o4) };
$oICE->stop;
$oCookies = $o4->cookie_jar;
# Exercise / test the native_query() function:
$o4->{_debug} = 1;
$oICE->start;
$o4->gui_query('query', {option1 => 1,
                         search_option2 => 2,
                        });
$oICE->stop;
$o4->{_debug} = 0;
$o4->gui_query('query', {option1 => 1,
                         search_option2 => 2,
                        });
# Exercise other set/get functions:
is($o4->date_from, '');
is($o4->date_to,   '');
is($o4->env_proxy, 0);
is($o4->http_proxy, undef);
is($o4->http_proxy_user, undef);
is($o4->http_proxy_pwd, undef);
$o4->date_from('dummydate');
$o4->date_to  ('dummydate');
$o4->env_proxy('dummydate');
$o4->http_proxy('dummydate');
$o4->http_proxy_user('dummydate');
$o4->http_proxy_pwd('dummydate');
is($o4->date_from, 'dummydate');
is($o4->date_to,   'dummydate');
is($o4->env_proxy, 'dummydate');
is_deeply($o4->http_proxy, ['dummydate']);
is($o4->http_proxy_user, 'dummydate');
is($o4->http_proxy_pwd, 'dummydate');
# Sanity-tests for proxy stuff:
my $o6 = new WWW::Search;
ok(! $o6->is_http_proxy);
ok(! $o6->is_http_proxy_auth_data);
$o6->http_proxy('');
ok(! $o6->is_http_proxy);
ok(! $o6->is_http_proxy_auth_data);
$o6->http_proxy('some', 'things');
ok($o6->is_http_proxy);
ok(! $o6->is_http_proxy_auth_data);
$o6->http_proxy_user('something');
ok(! $o6->is_http_proxy_auth_data);
$o6->http_proxy_pwd('something');
# use Data::Dumper;
# print STDERR Dumper(\$o6);
ok($o6->is_http_proxy_auth_data);
# Sanity-tests for the timeout() method:
is($o6->timeout, 60);
$o6->timeout(120);
is($o6->timeout, 120);
is(WWW::Search::strip_tags('hello<TAG> <TAG2>world'), 'hello world');
ok($o6->user_agent('non-robot'));
ok($o6->agent_name('junk'));
is($o6->agent_name, 'junk');
is($o6->agent_name, 'junk');
ok(! $o6->agent_email('junk'));
is($o6->agent_email, 'junk');
is($o6->agent_email, 'junk');
ok($o6->user_agent);
ok(! $o6->http_referer('junk'));
is($o6->http_referer, 'junk');
is($o6->http_referer, 'junk');
ok($o6->http_method('junk'));
is($o6->http_method, 'junk');
is($o6->http_method, 'junk');

# Tests for WWW::SearchResult:
my $oWSR = new WWW::SearchResult;
$oWSR->add_url('url1');
$oWSR->thumb_url('url1.thumb');
$oWSR->image_url('url1.png');
$oWSR->title('title1');
$oWSR->description('description1');
$oWSR->change_date("yesterday");
$oWSR->start_date("last Tuesday");
$oWSR->index_date("today");
$oWSR->end_date("tomorrow");
$oWSR->raw(qq{<A HREF="url1">title1</a>});
$oWSR->score(99);
$oWSR->normalized_score(990);
$oWSR->size(4096);
$oWSR->source('WWW::Search');
$oWSR->company('Dub Dub Dub Search, Inc.');
$oWSR->location('Ashburn, VA');
$oWSR->bid_amount(9.99);
$oWSR->shipping(4.85);
$oWSR->bid_count(9);
$oWSR->question_count(3);
$oWSR->watcher_count(65);
$oWSR->item_number(987654321);
$oWSR->category(7654);
$oWSR->bidder('Joe');
$oWSR->seller('Jane');
ok($o4->result_as_HTML($oWSR));
is($o4->result_as_HTML(), '');
is($o4->result_as_HTML(undef), '');
is($o4->result_as_HTML(0), '');
is($o4->result_as_HTML(1), '');
is($o4->result_as_HTML([1,2]), '');
my $s = $oWSR->as_HTML;
# Other miscellaneous sanity checks and coverage tests:
is(&WWW::Search::escape_query, '');
my @a = &WWW::Search::unescape_query(qw(a b c));
$o2->strip_tags('a', undef, 'b');
delete $ENV{WWW_SEARCH_USERAGENT};
$o2->user_agent(1);
$o2->user_agent;
$ENV{WWW_SEARCH_USERAGENT} = 'No::Such::Module';
$oICE->start;
$o2->user_agent(1);
$o2->user_agent;
$oICE->stop;
my $sICE = join("\n", $oICE->read);
like($sICE, qr'can not load');
$ENV{WWW_SEARCH_USERAGENT} = 'Carp';  # a module which does not have a new()
$oICE->start;
$o2->user_agent(1);
$o2->user_agent;
$oICE->stop;
$sICE = join("\n", $oICE->read);
like($sICE, qr'can not create');
$s = qq{foo\nbar\nbaz};
$o2->split_lines($s);
$o2->split_lines(['a'], $s);
$o2->generic_option;
$o2->_native_setup_search;
$o2->user_agent_delay;
$o2->user_agent_delay(1);
$o2->absurl;
$o2->absurl('foo');
$o2->absurl('foo', 'bar');
$o2->need_to_delay;
$o2->_parse_tree;
$o2->_native_retrieve_some;
$o2->preprocess_results_page;
$o2->preprocess_results_page('foo');
$o2->test_cases;
$o2->hash_to_cgi_string;
$o2->hash_to_cgi_string({
                         foo => 'foo',
                         bar => undef,
                         undef => 'baz',
                         empty => '',
                        });
exit 0;

foreach my $sEngine (@as)
  {
  my $o;
  # diag(qq{trying $sEngine});
  eval { $o = new WWW::Search($sEngine) };
  ok(ref($o), qq{loaded WWW::Search::$sEngine}); # } ) # Emacs bug
  } # foreach

exit 0;

__END__

