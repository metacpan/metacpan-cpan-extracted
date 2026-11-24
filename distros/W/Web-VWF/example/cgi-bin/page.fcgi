#!/usr/bin/env perl

# Can be tested at the command line, e.g.:
#	LANG=en_GB CONFIG_DIR=example/conf perl -Ilib example/cgi-bin/page.fcgi page=index
# To mimic a French mobile site:
#	CONFIG_DIR=example/conf perl -Ilib example/cgi-bin/page.fcgi --mobile page=index lang=fr
# To turn off the linting of HTML on a search-engine landing page
#	CONFIG_DIR=example/conf perl -Ilib example/cgi-bin/page.fcgi --search-engine page=index lint_content=0

# A site that keeps its modules in a private directory (cpanm -l ~/perl5, or
# local::lib) adds it here, and it must be the first code in the file: pragmas
# such as autodie load List::Util and Scalar::Util, and once the system copies
# are loaded a newer one in the private directory fails to load against them
# ("List::Util version 1.70 required--this is only version 1.63").
# lib->import and not a plain unshift: it also adds the architecture
# subdirectory, where the compiled (XS) modules are.  Under a web server
# PERL5LIB is not set, so this cannot be left to the environment.
#
# BEGIN {
#	$ENV{'HOME'} ||= '/home/example';	# not set for a FastCGI worker
#	require lib;
#	lib->import('/home/example/perl5/lib/perl5');
# }

BEGIN {
	# Sanitize environment variables
	delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
	$ENV{'PATH'} = '/usr/local/bin:/bin:/usr/bin';	# For insecurity
}

use strict;
use warnings;
use autodie qw(:all);

use FindBin;

use Web::VWF;

Web::VWF->new({ directory => "$FindBin::Bin/../conf" })->run();
