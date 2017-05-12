#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 6;

use WebService::StreetMapLink;


for my $name ( 'United States of America',
               'United States',
               'U.S.A',
               'U.S.',
             )
{
    is( WebService::StreetMapLink->_sanitize_country($name),
        'usa',
        "_sanitize_country for $name"
      );
}

for my $name ( 'United Kingdom',
               'U.K.',
             )
{
    is( WebService::StreetMapLink->_sanitize_country($name),
        'uk',
        "_sanitize_country for $name"
      );
}

