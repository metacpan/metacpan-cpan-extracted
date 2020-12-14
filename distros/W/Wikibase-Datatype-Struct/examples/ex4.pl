#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Struct::Sitelink qw(struct2obj);

# Item structure.
my $struct_hr = {
        'badges' => [],
        'site' => 'enwiki',
        'title' => 'Main page',
};

# Get object.
my $obj = struct2obj($struct_hr);

# Get badges.
my $badges_ar = [map { $_->value } @{$obj->badges}];

# Get site.
my $site = $obj->site;

# Get title.
my $title = $obj->title;

# Print out.
print 'Badges: '.(join ', ', @{$badges_ar})."\n";
print "Site: $site\n";
print "Title: $title\n";

# Output:
# Badges:
# Site: enwiki
# Title: Main page