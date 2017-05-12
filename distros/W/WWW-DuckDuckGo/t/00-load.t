#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('WWW::DuckDuckGo');
    use_ok('WWW::DDG');
    use_ok('WWW::DuckDuckGo::ZeroClickInfo');
    use_ok('WWW::DuckDuckGo::Link');
    use_ok('WWW::DuckDuckGo::Icon');
}

done_testing;
