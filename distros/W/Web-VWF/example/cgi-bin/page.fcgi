#!/usr/bin/perl -w

# Can be tested at the command line, e.g.:
#	LANG=en_GB CONFIG_DIR=example/conf perl -Ilib example/cgi-bin/page.fcgi page=index
# To mimic a French mobile site:
#	CONFIG_DIR=example/conf perl -Ilib example/cgi-bin/page.fcgi --mobile page=index lang=fr
# To turn off the linting of HTML on a search-engine landing page
#	CONFIG_DIR=example/conf perl -Ilib example/cgi-bin/page.fcgi --search-engine page=index lint_content=0

use strict;
use warnings;
use autodie qw(:all);

use FindBin;

use Web::VWF;

Web::VWF->new({ directory => "$FindBin::Bin/../conf" })->run();
