use inc::Module::Install;
use Module::Install::XSUtil 0.39;

name 'Win32-Unicode';
all_from 'lib/Win32/Unicode.pm';

configure_requires 'ExtUtils::ParseXS' => 2.21;
use_ppport 3.19;
cc_warnings;
cc_src_paths 'xs';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More'        => 0.98;
test_requires 'Test::Output'      => 1.01;
test_requires 'Test::Exception'   => 0.31;
test_requires 'Test::Mock::Guard' => 0.08;

repository 'https://github.com/xaicron/p5-win32-unicode';
bugtracker 'https://github.com/xaicron/p5-win32-unicode/issues';

WriteAll;
