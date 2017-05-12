use strict;
use warnings;

use Test::More tests => 1;
use WebService::Solr::Tiny;

my $solr = WebService::Solr::Tiny->new;

my %got = %WebService::Solr::Tiny::;

# We only want to test what methods we've added, remove perl ones.
delete @got{ qw/__ANON__ AUTOLOAD BEGIN DESTROY VERSION import/ };

# __NAMESPACE_CLEAN_STORAGE is an implementation detail because we use
# namespace::clean, it would be nicer not to leave that in the namespace.
is_deeply [ sort keys %got ], [ qw/new search/ ],
    'package only has "new", "search" subs';
