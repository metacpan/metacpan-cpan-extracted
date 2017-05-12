#!/usr/bin/perl -w
use strict;
use warnings;

use WWW::Search::Test;
use Test::More skip_all => 'torrentz.eu was shut down';

BEGIN { use_ok('WWW::Search::Torrentz') };

tm_new_engine('Torrentz');
tm_run_test(normal => $WWW::Search::Test::bogus_query, 0, 0);
tm_run_test(normal => 'linux', 20, undef);

done_testing;
