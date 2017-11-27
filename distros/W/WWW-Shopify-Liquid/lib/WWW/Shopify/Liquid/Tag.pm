#!/usr/bin/perl

use strict;
use warnings;

use WWW::Shopify::Liquid;

package WWW::Shopify::Liquid::Tag;
use base 'WWW::Shopify::Liquid::Element';

sub inner_tags { return (); }
sub abstract { my $package = ref($_[0]) ? ref($_[0]) : $_[0]; return ($package eq __PACKAGE__); }
sub name { my $package = ref($_[0]) ? ref($_[0]) : $_[0]; $package =~ s/^.*:://; $package =~ s/([a-z])([A-Z])/$1_$2/g; return lc($package);  }
sub new { 
	my ($package, $line, $tag, $arguments, $contents) = @_;
	my $self = { line => $line, core => $tag, arguments => $arguments, contents => $contents };
	return bless $self, $package;
}
sub is_free { return 0; }
sub is_enclosing { return 0; }
sub min_arguments { return 0; }
sub max_arguments { return undef; }


1;
