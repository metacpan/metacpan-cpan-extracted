#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::Diff::FormattedHTML' ) || print "Bail out!\n";
}

diag( "Testing Text::Diff::FormattedHTML $Text::Diff::FormattedHTML::VERSION, Perl $], $^X" );

# open OUT, ">_.html";
# print OUT "<style type='text/css'>\n", diff_css(), "</style>\n";
# print OUT diff_files('t/fileA', 't/fileB');
# close OUT;
