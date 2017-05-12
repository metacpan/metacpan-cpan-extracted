# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-Search-TheITJobBoard.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Data::Dumper;
use lib '../lib';
use Test::More;

BEGIN {
	eval { use LWP::UserAgent };
	if ($@){
		diag "LWP not found";
		plan tests => 1;
		use_ok('WWW::Search::TheITJobBoard' => 0.04);
		exit;
	}
	else {
		my $ua = LWP::UserAgent->new;
		$ua->timeout(10);
		$ua->env_proxy;
		my $response = $ua->get('http://search.cpan.org/');
		if (not $response or $response->is_error ) {
			diag "LWP cannot get cpan, guess we're not able to get online";
			plan tests => 1;
			use_ok('WWW::Search::TheITJobBoard' => 0.04);
			exit;
		} else {
			plan tests => 7;
			use_ok('WWW::Search::TheITJobBoard' => 0.04);
			pass('can get cpan with LWP-UserAgent');
		}
	}
}

my $s = WWW::Search->new('TheITJobBoard', _debug=>0, detailed=>1,);
isa_ok($s, 'WWW::Search::TheITJobBoard');
is($s->{detailed}, 1, 'Passed arg');
is(WWW::Search::TheITJobBoard::CONTRACT, 1, 'Constants');

my $q = WWW::Search::escape_query("perl html");
ok(defined($q),'Query escaped');
is($q, 'perl+html', 'Query value');

__END__

# diag Dumper $s;

ok(defined($s->native_query($q,
	jobtype			=> WWW::Search::TheITJobBoard::CONTRACT,
	'location[]'	=> 180,
	orderby			=> WWW::Search::TheITJobBoard::NONAGENCY,
)),'Native query');

my $hits = 0;
while ( my $r = $s->next_result() ){
	++$hits;
	isa_ok($r, 'WWW::SearchResult');
}

diag Dumper $s;
diag "Got $hits";


