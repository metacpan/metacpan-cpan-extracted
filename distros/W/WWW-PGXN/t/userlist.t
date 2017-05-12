#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;
use Test::More tests => 4;
#use Test::More 'no_plan';
use WWW::PGXN;
use File::Spec::Functions qw(catfile);

SEARCHER: {
    package PGXN::API::Searcher;
    $INC{'PGXN/API/Searcher.pm'} = __FILE__;
}

# Set up the WWW::PGXN object.
my $pgxn = new_ok 'WWW::PGXN', [ url => 'file:t/mirror' ];

##############################################################################
# Try to get userlist when no template.
is $pgxn->get_userlist('t'), undef,
    'Should get no userlist when no userlist template';

# Add a template but fetch a non-existent file.
$pgxn->_uri_templates->{userlist} = URI::Template->new('/users/{letter}.json');
is_deeply $pgxn->get_userlist('z'), [],
    'Should get empty userlist when no userlist file';

# Now fetch an existing file.
is_deeply $pgxn->get_userlist('t'), [
    { user => 'theory', name => 'David E. Wheeler' },
    { user => 'tom',    name => 'Tom G. Lane' },
    { user => 'tony',   name => 'Tony Vanilla' },
], 'An existing userlist should be properly read in';
