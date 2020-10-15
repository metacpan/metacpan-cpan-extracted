#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Field;

package WWW::Shopify::Field::Identifier;
use parent 'WWW::Shopify::Field';
sub sql_type { return "bigint"; }
sub data_type { return WWW::Shopify::Field->TYPE_QUANTITATIVE; }
sub generate($) {
	return int(rand(100000000))+1;
}

package WWW::Shopify::Field::Identifier::String;
use parent 'WWW::Shopify::Field';
use String::Random qw(random_regex random_string);
sub sql_type { return "varchar(255)"; }
sub data_type { return WWW::Shopify::Field->TYPE_QUALITATIVE; }

sub generate($) {
	return ::random_regex('[0-9a-f]{32}');
}

1;
