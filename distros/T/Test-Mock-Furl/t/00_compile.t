use strict;
use Test::AllModules;

BEGIN {
    eval 'use Win32;1' if $^O && $^O =~ /Win32/;

    all_ok(
        search_path => 'Test::Mock::Furl',
        use_ok      => 1,
    );
}
