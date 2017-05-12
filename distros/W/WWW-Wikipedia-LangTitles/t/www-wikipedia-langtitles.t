# This is a test for module WWW::Wikipedia::LangTitles.

use warnings;
use strict;
use Test::More;
use utf8;
BEGIN {
    use_ok ('WWW::Wikipedia::LangTitles', 'get_wiki_titles', 'make_wiki_url');
};

my $url = make_wiki_url ('Monkey');
ok ($url);
my $jurl = make_wiki_url ('猿', lang => 'ja');
ok ($jurl);

done_testing ();
# Local variables:
# mode: perl
# End:
