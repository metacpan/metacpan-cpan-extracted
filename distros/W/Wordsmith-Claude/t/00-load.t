#!perl
use 5.020;
use strict;
use warnings;
use Test::More tests => 12;

BEGIN {
    use_ok('Wordsmith::Claude') || print "Bail out!\n";
    use_ok('Wordsmith::Claude::Options') || print "Bail out!\n";
    use_ok('Wordsmith::Claude::Result') || print "Bail out!\n";
    use_ok('Wordsmith::Claude::Mode') || print "Bail out!\n";
    use_ok('Claude::Agent::CLI') || print "Bail out!\n";
    use_ok('Wordsmith::Claude::Blog') || print "Bail out!\n";
    use_ok('Wordsmith::Claude::Blog::Builder') || print "Bail out!\n";
    use_ok('Wordsmith::Claude::Blog::Result') || print "Bail out!\n";
    use_ok('Wordsmith::Claude::Blog::Interactive') || print "Bail out!\n";
    use_ok('Wordsmith::Claude::Blog::Reviewer') || print "Bail out!\n";
}

diag("Testing Wordsmith::Claude $Wordsmith::Claude::VERSION, Perl $], $^X");

# Test exports
can_ok('Wordsmith::Claude', 'rewrite');
can_ok('Wordsmith::Claude', 'question');
