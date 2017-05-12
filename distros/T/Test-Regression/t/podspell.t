use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Spelling; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test::Spelling required to criticise code';
   plan( skip_all => $msg );
}

Test::Spelling::add_stopwords(qw(CPAN Bamber Walde AnnoCPAN RT internalId lang param HTML URLs href sitemap SQL bladger javascript loopName URL globalvars pageId pageid sitemaps XML changefreq en lastmod notfound pagelookup runmode runmodes url utf namespace upto stderr yml toolic Filip Grali));
Test::Spelling::all_pod_files_spelling_ok();

