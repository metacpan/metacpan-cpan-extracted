#!/usr/bin/perl

use strict;
use warnings;


use String::Random qw(random_regex random_string);
use Data::Random;

package WWW::Shopify::Field::Text;
use parent 'WWW::Shopify::Field';
sub sql_type { return "text"; }

my @utf8_characters = split(//, '漢字仮名交じり文åФХѾЦЧШЩЪЫЬѢꙖѤЮѦѪѨѬѠѺѮѰѲѴΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ');
sub rand_utf8_char { return rand() < 0.5 ? $utf8_characters[int(rand(int(@utf8_characters)))] : ''; }

sub generate($) {
	return $_[0]->{arguments}->[0] if int(@{$_[0]->{arguments}} > 0);
	#return join("", map { chr(int(rand()*10000+100)) } 1..(rand(16)+1));
	return join("-", map { lc($_) . __PACKAGE__->rand_utf8_char() } ::rand_words(size => int(rand(10000))+1));
}


package WWW::Shopify::Field::Text::HTML;
use parent 'WWW::Shopify::Field::Text';
sub generate($) {
	return "<html>" . WWW::Shopify::Field::Text::generate($_[0]) . "</html>";
}

1;
