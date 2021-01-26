#!/usr/bin/env perl

use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8 encode_utf8);
use Wikibase::Datatype::Sitelink;
use Wikibase::Datatype::Value::Item;

# Object.
my $obj = Wikibase::Datatype::Sitelink->new(
        'badges' => [
                 Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q123',
                 ),
        ],
        'site' => 'cswiki',
        'title' => decode_utf8('Hlavní strana'),
);

# Get badges.
my $badges_ar = [map { $_->value } @{$obj->badges}];

# Get site.
my $site = $obj->site;

# Get title.
my $title = $obj->title;

# Print out.
print 'Badges: '.(join ', ', @{$badges_ar})."\n";
print "Site: $site\n";
print 'Title: '.encode_utf8($title)."\n";

# Output:
# Badges: Q123
# Site: cswiki
# Title: Hlavní strana