#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Tag::Free;
use base 'WWW::Shopify::Liquid::Tag';
sub is_free { return 1; }
sub abstract { my $package = ref($_[0]) ? ref($_[0]) : $_[0]; return ($package eq __PACKAGE__); }
sub tokens { return ($_[0], map { $_->tokens } grep { defined $_ } (@{$_[0]->{arguments}})); }
sub new { 
	my ($package, $line, $tag, $arguments) = @_;
	my $self = { line => $line, core => $tag, arguments => $arguments };
	return bless $self, $package;
}

1;