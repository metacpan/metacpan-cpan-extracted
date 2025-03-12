#! perl -w
use strict;
use warnings;
use Test::More;

BEGIN {
    eval "use Test::Script 1.09";
    if ($@) {
        plan skip_all => "Test::Script 1.09 is required for testing bin/ujconv";
    }
    else {
        plan tests => 2;
    }
}

script_compiles 'bin/ujconv';

subtest 'stdin' => sub {
    plan tests => 2;

    script_runs ['bin/ujconv', '-f', 'utf8', '-t', 'sjis'],
      {stdin => \"\xe6\x84\x9b"};

    script_stdout_is "\x88\xa4";
};
