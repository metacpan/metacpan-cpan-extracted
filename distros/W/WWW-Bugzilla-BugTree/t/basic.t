use strict;
use warnings;
use 5.012;
use Test::More tests => 3;
use WWW::Bugzilla::BugTree;

my $tree = eval { WWW::Bugzilla::BugTree->new };
diag $@ if $@;

isa_ok $tree, 'WWW::Bugzilla::BugTree';
isa_ok eval { $tree->ua }, 'LWP::UserAgent';
diag $@ if $@;

isa_ok eval { $tree->url }, 'URI';
diag $@ if $@;
