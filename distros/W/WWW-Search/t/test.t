
# $Id: test.t,v 1.6 2008-11-27 22:33:40 Martin Exp $

# Tests for the WWW::Search::Test module

use File::Spec::Functions;
use ExtUtils::testlib;
use Test::More qw(no_plan);

use strict;

BEGIN { use_ok('WWW::Search::Test') };

my $sWebsearch1 = WWW::Search::Test::find_websearch();
ok($sWebsearch1, 'found any WebSearch (first time)');
# Call it again to trigger memoization code:
my $sWebsearch2 = WWW::Search::Test::find_websearch();
ok($sWebsearch2, 'found any WebSearch (second time)');
is($sWebsearch1, $sWebsearch2, 'both WebSearch are the same');
diag($sWebsearch1);
pass;

1;

__END__

