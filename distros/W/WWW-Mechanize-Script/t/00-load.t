#!perl -T

use Test::More tests => 1;

BEGIN
{
    use_ok('WWW::Mechanize::Script') || print "Bail out!\n";
}

diag("Testing WWW::Mechanize::Script $WWW::Mechanize::Script::VERSION, Perl $], $^X");
